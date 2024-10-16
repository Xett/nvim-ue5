--- Initialise Module
local fstruct = {}
function fstruct.get(Module)
	return {
		name = 'fstruct',
		command_name = 'UEStruct',
		command_description = 'Insert an FStruct header snippet',
		arguments = {
			params = {
				default = nil,
				string_parse_function = Module.snippets.parse_macro_parameters_snippet,
			},
			parents = {
				default = nil,
				string_parse_function = Module.utils.parse_comma_seperated,
			},
		},
		build_table = function(Module, arg_table)
			return {
				'USTRUCT(' .. Module.snippets.generate_macro_parameters_snippet(Module, arg_table.params) .. ')',
				'struct F' .. arg_table.name .. Module.snippets.generate_parent_classes_snippet(Module, arg_table.parents),
				'{',
				'\tGENERATED_BODY()',
				'',
				'};',
				'',
			}
		end,
		apply_tab_string = function(Module, tab_string, build_table)
			for index, value in ipairs(build_table) do
				if index ~= 5 and index ~= 7 then
					build_table[index] = tab_string .. value
				end
			end
		end,
	}
end

--- Return Module
return fstruct
