--- Initialise Module
local interface = {}
function interface.get(Module)
	return {
		name = 'interface',
		command_name = 'UEInterface',
		command_description = 'Insert a UInterface and an IInterface header snippet',
		arguments = {
			params = {
				default = nil,
				string_parse_function = Module.snippets.parse_macro_parameters_snippet,
			},
			uparents = {
				default = 'UInterface',
				string_parse_function = Module.utils.parse_comma_seperated,
			},
			iparents = {
				default = nil,
				string_parse_function = Module.utils.parse_comma_seperated,
			},
		},
		build_table = function(Module, arg_table)
			return {
				'UINTERFACE(' .. Module.snippets.generate_macro_parameters_snippet(Module, arg_table.params) .. ')',
				'class U' .. arg_table.name .. Module.snippets.generate_parent_classes_snippet(Module, arg_table.uparents),
				'{',
				'\tGENERATED_UINTERFACE_BODY()',
				'};',
				'',
				'class I' .. arg_table.name .. Module.snippets.generate_parent_classes_snippet(Module, arg_table.iparents),
				'{',
				'\tGENERATED_IINTERFACE_BODY()',
				'',
				'};',
				'',
			}
		end,
		apply_tab_string = function(Module, tab_string, build_table)
			for index, value in ipairs(build_table) do
				if index ~= 6 and index ~= 10 and index ~= 12 then
					text[index] = tab_string .. value
				end
			end
		end,
	}
end

--- Return Module
return interface
