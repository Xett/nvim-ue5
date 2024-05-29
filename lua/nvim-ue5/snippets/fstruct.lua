local fstruct = {}

function fstruct.bind(Module)
	vim.api.nvim_create_user_command('UEStruct',
		function(opts)
			local struct_name = opts['fargs'][1]

			if struct_name == nil or struct_name == '' then
				vim.api.nvim_err_writeln("Missing struct name")
				return
			end

			local ustruct_parameters_string = ''
			local parent_structs_string = ''

			if opts['fargs'][2] ~= nil then
				local arg2_type, arg2 = Module.commands.parse_named_command_argument(opts['fargs'][2])
				if arg2_type == 'params' then
					ustruct_parameters_string = arg2
				elseif arg2_type == 'parents' then
					parent_structs_string = arg2
				end
			end

			if opts['fargs'][3] ~= nil then
				local arg3_type, arg3 = Module.commands.parse_named_command_argument(opts['fargs'][3])
				if arg3_type == 'params' then
					ustruct_parameters_string = arg3
				elseif arg3_type == 'parents' then
					parent_structs_string = arg3
				end
			end

			local ustruct_parameters = Module.snippets.parse_macro_parameters_string(Module, ustruct_parameters_string)
			local parent_structs = Module.utils.parse_comma_seperated(parent_structs_string)

			fstruct.generate_struct(Module, struct_name, ustruct_parameters, parent_structs)
		end,
		{
			nargs='*',
			desc="Insert an FStruct header snippet",	
		})
end

function fstruct.unbind(Module)
	vim.api.nvim_del_user_command('UEStruct')
end

function fstruct.generate_struct(Module, struct_name, ustruct_params, parent_structs)
	local tabs_string = Module.utils.get_tabs_string()

	local text = {
		tabs_string .. 'USTRUCT(' .. Module.snippets.parse_macro_parameters(Module, ustruct_params) .. ')',
		tabs_string .. 'struct F' .. struct_name .. Module.snippets.parse_parent_classes(Module, parent_structs),
		tabs_string .. '{',
		tabs_string .. '\tGENERATED_BODY()',
		'',
		tabs_string .. '};',
		'',
	}

	Module.utils.write_to_current_buffer_line(text)
end

return fstruct
