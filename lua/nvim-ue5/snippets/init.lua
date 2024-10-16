--- Initialise Module
local snippets = {}
snippets.modules = {}

snippets.ui = require('nvim-ue5.snippets.ui')

snippets.modules_to_load = {
	require('nvim-ue5.snippets.uclass'),
	require('nvim-ue5.snippets.aactor'),
	require('nvim-ue5.snippets.fstruct'),
	require('nvim-ue5.snippets.interface'),
}
function snippets.init(Module)
	for _, snippet_module in ipairs(snippets.modules_to_load) do
		local mod_def = snippet_module.get(Module)
		snippets.modules[mod_def.name] = mod_def
	end
end

--- Bind Commands
function snippets.bind(Module)
	snippets.ui.bind(Module)

	for snippet_name, snippet_module in pairs(snippets.modules) do
		vim.api.nvim_create_user_command(snippet_module.command_name,
			function(opts)
				local arg_table = {}

				--- First argument is ALWAYS the name (without the prefix)
				arg_table.name = opts['fargs'][1]

				--- Raise an error if the name is missing
				if arg_table.name == nil or arg_table.name == '' then
					 vim.api.nvim_err_writeln("Missing name!")
					 return
				end

				for i = 2, #snippet_modules.arguments+1 do
					if opts['fargs'][i] ~= nil then
						local argument_type, argument = Module.commands.parse_named_command_argument(opts['fargs'][i])
						if snippet_modules.arguments[argument_type] then
							arg_table[argument_type] = snippet_module.arguments[argument_type].string_parse_function(Module, argument)
						else
							vim.api.nvim_err_writeln(argument_type .. " is not recognised")
							return
						end
					end
				end

				for argument_name, argument in arg_table do
					if argument == '' then
						if snippet_module.arguments[argument_name].default ~= nil then
							argument = snippet_module.arguments[argument_name].default
						end
					end
				end

				local text_to_write = snippet_module.build_table(Module, arg_table)
				snippet_module.apply_tab_string(Module, Module.utils.get_tab_string(), text_to_write)

				Module.utils.write_to_current_buffer_line(text_to_write)
			end,
			{
				nargs='*',
				desc=snippet_module.command_description,
			}
		)
	end		
end

--- Unbind Commands
function snippets.unbind(Module)
	snippets.ui.unbind(Module)

	for _, snippet_module in ipairs(snippets.modules) do
		vim.api.nvim_del_user_command(snippet_module.command_name)
	end	
end

--- Parse the macro parameters input argument into a table
function snippets.parse_macro_parameters_string(Module, params_string)
	local comma_seperated_elements = Module.utils.parse_comma_seperated(Module, params_string)

	local params = {}
	for index, element in ipairs(comma_seperated_elements) do
		if string.find(element, '=') then
			local key, value = string.match(element, "([^=]+)=(.+)")
			local inner = string.match(value, '%((.-)%)')
			if inner then
				params[key] = {}
				local inner_elements = {}
				for inner_element in inner:gmatch('([^,]+)') do
					table.insert(inner_elements, inner_element)
				end
				for inner_index, inner_element in ipairs(inner_elements) do
					if string.find(inner_element, '=') then
						local inner_key, inner_value = string.match(inner_element, '([^=]+)=(.+)')
						params[key][inner_key] = inner_value
					else
						params[key][inner_index] = inner_element
					end
				end
			end
		else
			params[index] = element
		end
	end
	
	return params
end

--- Generate the macro parameters string, used in the snippet generator
function snippets.generate_macro_parameters_snippet(Module, parameters)
	local params_string = ""
	local first = true

	if parameters == nil then
		return params_string
	end
	
	for key, value in pairs(parameters) do
		local param_string = ""

		if type(key) == "number" then
			param_string = value
		elseif type(key) == "string" then
			param_string = key .. '='
			if type(value) == "string" then
				param_string = param_string .. value
			elseif type(value) == "table" then
				param_string = param_string .. '('
				param_string = param_string .. snippets.parse_macro_parameters_string(Module, value)
				param_string = param_string .. ')'
			end
		end
		
		if first then
			params_string = params_string .. param_string
			first = false
		else
			params_string = params_string .. ', ' .. param_string
		end
	end
	
	return params_string
end

--- Generate the parent classes string, used in the snippet generator
function snippets.generate_parent_classes_snippet(Module, parent_classes)
	if parent_classes == nil then
		return ''
	end

	if #parent_classes > 0 then
		local parents_string = ' : public '
		local first = true
		for _, value in ipairs(parent_classes) do
			if first then
				parents_string = parents_string .. value
				first = false
			else
				parents_string = parents_string .. ', ' .. value
			end
		end
		return parents_string
	end

	return ''
end

--- Return Module
return snippets
