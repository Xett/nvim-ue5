--- Initialise Module
local snippets = {}

--- The snippet modules
snippets.modules = {
	require('nvim-ue5.snippets.uclass'),
	require('nvim-ue5.snippets.aactor'),
	require('nvim-ue5.snippets.fstruct'),
	require('nvim-ue5.snippets.interface'),
}

--- Bind Commands
function snippets.bind(Module)
	for _, snippet_module in ipairs(snippets.modules) do
		snippet_module.bind(Module)
	end		
end

--- Unbind Commands
function snippets.unbind(Module)
	for _, snippet_module in ipairs(snippets.modules) do
		snippet_module.unbind(Module)
	end	
end

--- Parse the macro parameters input argument into a table
function snippets.parse_macro_parameters_string(Module, params_string)
	local comma_seperated_elements = Module.utils.parse_comma_seperated(params_string)

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
				param_string = param_string .. snippets.parse_macro_parameters(Module, value)
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
