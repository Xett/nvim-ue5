--- Initialise Module
local interface = {}

--- Bind Commands
function interface.bind(Module)
	vim.api.nvim_create_user_command('UEInterface',
		function(opts)
			--- First argument is ALWAYS the interface name (without the prefix)
			local interface_name = opts['fargs'][1]

			--- Raise an error if the interface name is missing
			if interface_name == nil or interface_name == '' then
				vim.api.nvim_err_writeln("Missing interface name")
				return
			end

			--- VARIABLES
			local uinterface_parameters_string = ''
			local uinterface_parents_string = ''
			local iinterface_parents_string = ''

			--- We can take in 3 extra arguments, for the parameters, the UInterface parents, and the IInterface parents.
			--- The order of them doesn't matter since they have to be decalred, and omitting them means they will revert to default.
			--- We set the arguments to the strings, so that if there was no argument passed in, the strings will be empty.
			for i = 2, 3, 4 do
				if opts['fargs'][i] ~= nil then
					local argument_type, argument = Module.commands.parse_named_command_argument(opts['fargs'][i])
					if argument_type == 'args' then
						uinterface_parameters_string = argument
					elseif argument_type == 'uparents' then
						uinterface_parents_string = argument or 'UInterface'
					elseif argument_type == 'iparents' then
						iinterface_parents_string = argument
					end
				end
			end

			--- If there are no UInterface parent classes in the string, default to UInterface
			if uinterface_parents_string == '' then
				uinterface_parents_string = 'UInterface'
			end

			--- Parse the set strings, that we will actually parse into the snipper generator function
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

--- Unbind Commands
function interface.unbind(Module)
	vim.api.nvim_del_user_command('UEInterface')
end

--- Generate the UINTERFACE and IINTERFACE snippets
function interface.generate_interface(Module, interface_name, uinterface_params, uinterface_parents, iinterface_parents)
	local tabs_string = Module.utils.get_tabs_string()

	local text = {
		tabs_string .. 'UINTERFACE(' .. Module.snippets.generate_macro_parameters_snippet(Module, uinterface_params) .. ')',
		tabs_string .. 'class U' .. interface_name .. Module.snippets.generate_parent_classes_snippet(Module, uinterface_parents),
		tabs_string .. '{',
		tabs_string .. '\tGENERATED_UINTERFACE_BODY()',
		tabs_string .. '};',
		'',
		tabs_string .. 'class I' .. interface_name .. Module.snippets.generate_parent_classes_snippet(Module, iinterface_parents),
		tabs_string .. '{',
		tabs_string .. '\tGENERATED_IINTERFACE_BODY()',
		'',
		tabs_string .. '};',
		'',
	}

	Module.utils.write_to_current_buffer_line(text)
end

--- Return Module
return interface
