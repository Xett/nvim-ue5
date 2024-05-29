local uclass = {}

function uclass.bind(Module)
	vim.api.nvim_create_user_command('UEClass',
		function(opts)
			local class_name = opts['fargs'][1]	--- First argument is ALWAYS the class name (without the prefix)

			if class_name == nil or class_name == '' then
				vim.api.nvim_err_writeln("Missing class name")
				return
			end

			local uclass_parameters_string = ''
			local parent_classes_string = ''

			if opts['fargs'][2] ~= nil then
				local arg2_type, arg2 = Module.commands.parse_named_command_argument(opts['fargs'][2])
				if arg2_type == 'params' then
					uclass_parameters_string = arg2
				elseif arg2_type == 'parents' then
					parent_classes_string = arg2 or 'UObject'
				else
					vim.api.nvim_err_writeln(arg2_type .. " is not recognised")
					return
				end
			end

			if opts['fargs'][3] ~= nil then
				local arg3_type, arg3 = Module.commands.parse_named_command_argument(opts['fargs'][3])
				if arg3_type == 'params' then
					uclass_parameters_string = arg3
				elseif arg3_type == 'parents' then
					parent_classes_string = arg3 or 'UObject'
				else
					vim.api.nvim_err_writelin(arg3_type .. " is not recognised")
					return
				end
			end

			if parent_classes_string == '' then
				parent_classes_string = 'UObject'
			end

			local uclass_parameters = Module.snippets.parse_macro_parameters_string(Module, uclass_parameters_string)
			local parent_classes = Module.utils.parse_comma_seperated(parent_classes_string)

			uclass.generate_class(Module, class_name, uclass_parameters, parent_classes)
		end,
		{
			nargs='*',
			desc="Insert a UClass header snippet",			
		})
end

function uclass.unbind(Module)
	vim.api.nvim_del_user_command('UEClass')
end

function uclass.generate_class(Module, class_name, uclass_params, parent_classes)
	local tabs_string = Module.utils.get_tabs_string()

	local text = {
		tabs_string .. 'UCLASS(' .. Module.snippets.parse_macro_parameters(Module, uclass_params) .. ')',
		tabs_string .. 'class U' .. class_name .. Module.snippets.parse_parent_classes(Module, parent_classes),
		tabs_string .. '{',
		tabs_string .. '\tGENERATED_BODY()',
		'',
		tabs_string .. 'public:',
		tabs_string .. '\tU' .. class_name .. '();',
		tabs_string .. '};',
		'',
	}

	Module.utils.write_to_current_buffer_line(text)
end

return uclass
