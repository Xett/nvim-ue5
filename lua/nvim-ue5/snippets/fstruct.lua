--- Initialise Module
local fstruct = {}

--- Bind Commands
function fstruct.bind(Module)
	vim.api.nvim_create_user_command('UEStruct',
		function(opts)
			--- First argument is ALWAYS the struct name (without the prefix)
			local struct_name = opts['fargs'][1]

			--- Raise an error if the struct name is missing
			if struct_name == nil or struct_name == '' then
				vim.api.nvim_err_writeln("Missing struct name")
				return
			end

			--- VARIABLES
			local ustruct_parameters_string = ''
			local parent_structs_string = ''

			--- We can take 2 extra arguments, for the parameters and the parents.
			--- The order of them doesn't matter since they have to be declared, and omitting them means they will revert to default.
			--- We set the arguments to the strings, so that if there was no argument passed in, the strings will be empty.
			for i = 2, 3 do
				if opts['fargs'][2] ~= nil then
					local arg2_type, arg2 = Module.commands.parse_named_command_argument(opts['fargs'][2])
					if arg2_type == 'params' then
						ustruct_parameters_string = arg2
					elseif arg2_type == 'parents' then
						parent_structs_string = arg2
					else
						vim.api.nvim_err_writeln(argument_type .. " is not recognised")
						return
					end
				end
			end

			--- Parse the set strings, that we will actually parse into the snipper generator function
			local ustruct_parameters = Module.snippets.parse_macro_parameters_string(Module, ustruct_parameters_string)
			local parent_structs = Module.utils.parse_comma_seperated(parent_structs_string)

			fstruct.generate_struct(Module, struct_name, ustruct_parameters, parent_structs)
		end,
		{
			nargs='*',
			desc="Insert an FStruct header snippet",	
		})
end

--- Unbind Commands
function fstruct.unbind(Module)
	vim.api.nvim_del_user_command('UEStruct')
end

--- Generate the FSTRUCT snippet
function fstruct.generate_struct(Module, struct_name, ustruct_params, parent_structs)
	local tabs_string = Module.utils.get_tabs_string()

	local text = {
		tabs_string .. 'USTRUCT(' .. Module.snippets.generate_macro_parameters_snippet(Module, ustruct_params) .. ')',
		tabs_string .. 'struct F' .. struct_name .. Module.snippets.generate_parent_classes_snippet(Module, parent_structs),
		tabs_string .. '{',
		tabs_string .. '\tGENERATED_BODY()',
		'',
		tabs_string .. '};',
		'',
	}

	Module.utils.write_to_current_buffer_line(text)
end

--- Return Module
return fstruct
