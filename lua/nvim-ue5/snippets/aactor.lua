local aactor = {}

function aactor.bind(Module)
	vim.api.nvim_create_user_command('UEActor',
		function(opts)
			local actor_name = opts['fargs'][1]

			if actor_name == nil or actor_name == '' then
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
					parent_classes_string = arg2 or 'AActor'
				end
			end

			if opts['fargs'][3] ~= nil then
				local arg3_type, arg3 = Module.commands.parse_named_command_argument(opts['fargs'][3])
				if arg3_type == 'params' then
					uclass_parameters_string = arg3
				elseif arg3_type == 'parents' then
					parent_classes_string = arg3 or 'AActor'
				end
			end

			if parent_classes_string == '' then
				parent_classes_string = 'AActor'
			end

			local uclass_parameters = Module.snippets.parse_macro_parameters_string(Module, uclass_parameters_string)
			local parent_classes = Module.utils.parse_comma_seperated(parent_classes_string)

			aactor.generate_actor(Module, actor_name, uclass_parameters, parent_classes)
		end,
		{
			nargs='*',
			desc="Insert an AActor header snippet",			
		})
end

function aactor.unbind(Module)
	vim.api.nvim_del_user_command('UEActor')
end

function aactor.generate_actor(Module, actor_name, uclass_params, parent_classes)
	local tabs_string = Module.utils.get_tabs_string()

	local text = {
		tabs_string .. 'UCLASS(' .. Module.snippets.parse_macro_parameters(Module, uclass_params) .. ')',
		tabs_string .. 'class A' .. actor_name .. Module.snippets.parse_parent_classes(Module, parent_classes),
		tabs_string .. '{',
		tabs_string .. '\tGENERATED_BODY()',
		'',
		tabs_string .. '};',
		'',
	}

	Module.utils.write_to_current_buffer_line(text)
end

return aactor
