--- Initialise Module
local uclass = {}
function uclass.get(Module)
	return {
		name = 'uclass',
		command_name = 'UEClass',
		command_description = 'Insert a UClass header snippet',
		arguments = {
			params = {
				default = nil,
				string_parse_function = Module.snippets.parse_macro_parameters_snippet,
			},
			parents = {
				default = 'UObject',
				stringe_parse_function = Module.utils.parse_comma_seperated,
			},
		},
		build_table = function(Module, arg_table)
			return {
				'UCLASS(' .. Module.snippets.generate_macro_parameters_snippet(Module, arg_table.params) .. ')',
				'class U' .. arg_table.name .. Module.snippets.generate_parent_classes_snippet(Module, arg_table.parents),
				'{',
				'\tGENERATED_BODY()',
				'',
				'public:',
				'\tU' .. arg_table.name .. '();',
				'};',
				'',
			}
		end,
		apply_tab_string = function(Module, tab_string, build_table)
			for index, value in ipairs(build_table) do
				if index ~= 5 and index ~= 9 then
					build_table[index] = tab_string .. value
				end
			end
		end,
	}
end

-- Return Module
return uclass
