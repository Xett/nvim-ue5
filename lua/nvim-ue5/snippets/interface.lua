local interface = {}

function interface.bind(Module)
	vim.api.nvim_create_user_command('UEInterface',
		function(opts)
			local interface_name = opts['fargs'][1]

			if interface_name == nil or interface_name == '' then
				vim.api.nvim_err_writeln("Missing interface name")
				return
			end

			local uinterface_parameters_string = ''
			local uinterface_parents_string = ''
			local iinterface_parents_string = ''

			if opts['fargs'][2] ~= nil then
				local arg2_type, arg2 = Module.commands.parse_named_command_argument(opts['fargs'][2])
				if arg2_type == 'args' then
					uinterface_parameters_string = arg2
				elseif arg2_type == 'uparents' then
					uinterface_parents_string = arg2 or 'UInterface'
				elseif arg2_type == 'iparents' then
					iinterface_parents_string = arg2
				end
			end

			if opts['fargs'][3] ~= nil then
				local arg3_type, arg3 = Module.commands.parse_named_command_argument(opts['fargs'][3])
				if arg3_type == 'args' then
					uinterface_parameters_string = arg3
				elseif arg3_type == 'uparents' then
					uinterface_parents_string = arg3 or 'UInterface'
				elseif arg3_type == 'iparents' then
					iinterface_parents_string = arg3
				end
			end

			if opts['fargs'][4] ~= nil then
				local arg4_type, arg4 = Module.commands.parse_named_command_argument(opts['fargs'][4])
				if arg4_type == 'args' then
					uinterface_parameters_string = arg4
				elseif arg4_type == 'uparents' then
					uinterface_parents_string = arg4 or 'UInterface'
				elseif arg4_type == 'iparents' then
					iinterface_parents_string = arg4
				end
			end

			if uinterface_parents_string == '' then
				uinterface_parents_string = 'UInterface'
			end

			local uinterface_parameters = Module.snippets.parse_macro_parameters_string(Module, uinterface_parameters_string)
			local uinterface_parents = Module.utils.parse_comma_seperated(uinterface_parents_string)
			local iinterface_parents = Module.utils.parse_comma_seperated(iinterface_parents_string)

			interface.generate_interface(Module, interface_name, uinterface_parameters, uinterface_parents, iinterface_parents)
		end,
		{
			nargs='*',
			desc="Insert a UInterface and an IInterface header snippet",			
		})
end

function interface.unbind(Module)
	vim.api.nvim_del_user_command('UEInterface')
end

function interface.generate_interface(Module, interface_name, uinterface_params, uinterface_parents, iinterface_parents)
	local tabs_string = Module.utils.get_tabs_string()

	local text = {
		tabs_string .. 'UINTERFACE(' .. Module.snippets.parse_macro_parameters(Module, uinterface_params) .. ')',
		tabs_string .. 'class U' .. interface_name .. Module.snippets.parse_parent_classes(Module, uinterface_parents),
		tabs_string .. '{',
		tabs_string .. '\tGENERATED_UINTERFACE_BODY()',
		tabs_string .. '};',
		'',
		tabs_string .. 'class I' .. interface_name .. Module.snippets.parse_parent_classes(Module, iinterface_parents),
		tabs_string .. '{',
		tabs_string .. '\tGENERATED_IINTERFACE_BODY()',
		'',
		tabs_string .. '};',
		'',
	}

	Module.utils.write_to_current_buffer_line(text)
end

return interface
