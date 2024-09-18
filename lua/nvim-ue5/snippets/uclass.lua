--- Initialise Module
local uclass = {}

--- Bind Commands
function uclass.bind(Module)
	vim.api.nvim_create_user_command('UEClass',
		function(opts)
			--- First argument is ALWAYS the class name (without the prefix)
			local class_name = opts['fargs'][1]

			--- Raise an error if the class name is missing
			if class_name == nil or class_name == '' then
				vim.api.nvim_err_writeln("Missing class name")
				return
			end

			--- VARIABLES
			local uclass_parameters_string = ''
			local parent_classes_string = ''

			--- We can take in 2 extra arguments, for the parameters and parents.
			--- The order of them doesn't matter since they have to be declared, and omitting them means they will revert to default.
			--- We set the arguments to the strings, so that if there was no argument passed in, the strings will be empty.
			for i = 2, 3 do
				if opts['fargs'][i] ~= nil then
					local argument_type, argument = Module.commands.parse_named_command_argument(opts['fargs'][i])
					if argument_type == 'params' then
						uclass_parameters_string = argument
					elseif argument_type == 'parents' then
						parent_classes_string = argument or 'UObject'
					else
						vim.api.nvim_err_writeln(argument_type .. " is not recognised")
						return
					end
				end
			end

			--- If there are no parent classes in the string, default to UObject
			if parent_classes_string == '' then
				parent_classes_string = 'UObject'
			end

			--- Parse the set strings, that we will actually parse into the snippet generator function
			local uclass_parameters = Module.snippets.parse_macro_parameters_string(Module, uclass_parameters_string)
			local parent_classes = Module.utils.parse_comma_seperated(parent_classes_string)

			uclass.generate_class(Module, class_name, uclass_parameters, parent_classes)
		end,
		{
			nargs='*',
			desc="Insert a UClass header snippet",			
		})
end

--- Unbind Commands
function uclass.unbind(Module)
	vim.api.nvim_del_user_command('UEClass')
end

--- Generate the UCLASS snippet
function uclass.generate_class(Module, class_name, uclass_params, parent_classes)
	local tabs_string = Module.utils.get_tabs_string()

	local text = {
		tabs_string .. 'UCLASS(' .. Module.snippets.generate_macro_parameters_snippet(Module, uclass_params) .. ')',
		tabs_string .. 'class U' .. class_name .. Module.snippets.generate_parent_classes_snippet(Module, parent_classes),
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

--- Return Module
return uclass
