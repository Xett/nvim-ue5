local snippets = {}

local utils = require('nvim-ue5.utils')

function snippets.bind(Module)
	vim.api.nvim_create_user_command('UEClass',
		function(opts)
			local class_name = opts['fargs'][1]	--- First arguement is ALWAYS the class name (without the prefix)

			local uclass_parameters_string = ''
			local parent_classes_string = ''
			
			local arg2_type, arg2 = Module.commands.parse_named_command_argument(opts['fargs'][2])
			if arg2_type == 'params' then
				uclass_parameters_string = arg2
			elseif arg2_type == 'parents' then
				parent_classes_string = arg2 or 'UObject'
			end

			local arg3_type, arg3 = Module.commands.parse_named_command_argument(opts['fargs'][3])
			if arg3_type == 'params' then
				uclass_parameters_string = arg3
			elseif arg3_type == 'parents' then
				parent_classes_string = arg3 or 'UObject'
			end

			local uclass_parameters = Module.snippets.parse_macro_parameters_string(uclass_parameters_string)
			local parent_classes = Module.utils.parse_comma_seperated(parent_classes_string)

			Module.snippets.generate_class(class_name, uclass_parameters, parent_classes)
		end,
		{
			nargs='*',
			desc="Insert a UClass header snippet",			
		})
	vim.api.nvim_create_user_command('UEActor',
		function(opts)
			local actor_name = opts['fargs'][1]

			local uclass_parameters_string = ''
			local parent_classes_string = ''

			local arg2_type, arg2 = Module.commands.parse_named_command_argument(opts['fargs'][2])
			if arg2_type == 'params' then
				uclass_parameters_string = arg2
			elseif arg2_type == 'parents' then
				parent_classes_string = arg2 or 'AActor'
			end

			local arg3_type, arg3 = Module.commands.parse_named_command_argument(opts['fargs'][3])
			if arg3_type == 'params' then
				uclass_parameters_string = arg3
			elseif arg3_type == 'parents' then
				parent_classes_string = arg3 or 'AActor'
			end

			local uclass_parameters = Module.snippets.parse_macro_parameters_string(uclass_parameters_string)
			local parent_classes = Module.utils.parse_comma_seperated(parent_classes_string)

			Module.snippets.generate_actor(actor_name, uclass_parameters, parent_classes)
		end,
		{
			nargs='*',
			desc="Insert an AActor header snippet",			
		})

	vim.api.nvim_create_user_command('UEStruct',
		function(opts)
			local struct_name = opts['fargs'][1]

			local ustruct_parameters_string = ''
			local parent_structs_string = ''

			local arg2_type, arg2 = Module.commands.parse_named_command_argument(opts['fargs'][2])
			if arg2_type == 'params' then
				ustruct_parameters_string = arg2
			elseif arg2_type == 'parents' then
				parent_structs_string = arg2
			end

			local arg3_type, arg3 = Module.commands.parse_named_command_argument(opts['fargs'][3])
			if arg3_type == 'params' then
				ustruct_parameters_string = arg3
			elseif arg3_type == 'parents' then
				parent_structs_string = arg3
			end

			local ustruct_parameters = Module.snippets.parse_macro_parameters_string(ustruct_parameters_string)
			local parent_structs = Module.snippets.parse_parent_classes(parent_struct_string)

			Module.snippets.generate_struct(struct_name, ustruct_parameters, parent_structs)
		end,
		{
			nargs='*',
			desc="Insert an FStruct header snippet",	
		})

		vim.api.nvim_create_user_command('UEInterface',
		function(opts)
			local interface_name = opts['fargs'][1]

			local uinterface_parameters = ''
			local uinterface_parents = ''
			local iinterface_parents = ''

			local arg2_type, arg2 = Module.commands.parse_named_command_argument(opts['fargs'][2])
			if arg2_type == 'args' then
				uinterface_parameters = arg2
			elseif arg2_type == 'uparents' then
				uinterface_parents = arg2 or 'UInterface'
			elseif arg2_type == 'iparents' then
				iinterface_parents = arg2
			end

			local arg3_type, arg3 = Module.commands.parse_named_command_argument(opts['fargs'][3])
			if arg3_type == 'args' then
				uinterface_parameters = arg3
			elseif arg3_type == 'uparents' then
				uinterface_parents = arg3 or 'UInterface'
			elseif arg3_type == 'iparents' then
				iinterface_parents = arg3
			end

			local arg4_type, arg4 = Module.commands.parse_named_command_argument(opts['fargs'][4])
			if arg4_type == 'args' then
				uinterface_parameters = arg4
			elseif arg4_type == 'uparents' then
				uinterface_parents = arg4 or 'UInterface'
			elseif arg4_type == 'iparents' then
				iinterface_parents = arg4
			end

			Module.snippets.generate_interface(interface_name, uinterface_parameters, uinterface_parents, iinterface_parents)
		end,
		{
			nargs='*',
			desc="Insert a UInterface and an IInterface header snippet",			
		})
end

function snippets.unbind(Module)
	vim.api.nvim_del_user_command('UEClass')
	vim.api.nvim_del_user_command('UEStruct')
	vim.api.nvim_del_user_command('UEInterfact')
	vim.api.nvim_del_user_command('UEActor')
end

function snippets.parse_macro_parameters(parameters)
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
				param_string = param_string .. snippets.parse_macro_parameters(value)
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

function snippets.parse_macro_parameters_string(params_string)
	local comma_seperated_elements = utils.parse_comma_seperated(params_string)

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

function snippets.parse_parent_classes(parent_classes)
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

function snippets.generate_class(class_name, uclass_params, parent_classes)
	local tabs_string = utils.get_tabs_string()

	local text = {
		tabs_string .. 'UCLASS(' .. snippets.parse_macro_parameters(uclass_params) .. ')',
		tabs_string .. 'class U' .. class_name .. snippets.parse_parent_classes(parent_classes),
		tabs_string .. '{',
		tabs_string .. '\tGENERATED_BODY()',
		'',
		tabs_string .. 'public:',
		tabs_string .. '\tU' .. class_name .. '();',
		tabs_string .. '};',
		'',
	}

	utils.write_to_current_buffer_line(text)
end

function snippets.generate_struct(struct_name, ustruct_params, parent_structs)
	local tabs_string = utils.get_tabs_string()

	local text = {
		tabs_string .. 'USTRUCT(' .. snippets.parse_macro_parameters(ustruct_params) .. ')',
		tabs_string .. 'struct F' .. struct_name .. snippets.parse_parent_classes(parent_structs),
		tabs_string .. '{',
		tabs_string .. '\tGENERATED_BODY()',
		'',
		tabs_string .. '};',
		'',
	}

	utils.write_to_current_buffer_line(text)
end

function snippets.generate_interface(interface_name, uinterface_params, uinterface_parents, iinterface_parents)
	local tabs_string = utils.get_tabs_string()

	local text = {
		tabs_string .. 'UINTERFACE(' .. snippets.parse_macro_parameters(uinterface_params) .. ')',
		tabs_string .. 'class U' .. interface_name .. snippets.parse_parent_classes(uinterface_parents),
		tabs_string .. '{',
		tabs_string .. '\tGENERATED_UINTERFACE_BODY()',
		tabs_string .. '};',
		'',
		tabs_string .. 'class I' .. interface_name .. snippets.parse_parent_classes(iinterface_parents),
		tabs_string .. '{',
		tabs_string .. '\tGENERATED_IINTERFACE_BODY()',
		'',
		tabs_string .. '};',
		'',
	}

	utils.write_to_current_buffer_line(text)
end

function snippets.generate_actor(actor_name, uclass_params, parent_classes)
	local tabs_string = utils.get_tabs_string()

	local text = {
		tabs_string .. 'UCLASS(' .. snippets.parse_macro_parameters(uclass_params) .. ')',
		tabs_string .. 'class A' .. actor_name .. snippets.parse_parent_classes(parent_structs),
		tabs-string .. '{',
		tabs_string .. '\tGENERATED_BODY()',
		'',
		tabs_string .. '};',
		'',
	}

	utils.write_to_current_buffer_line(text)
end

return snippets
