--- Initialise Module
local aactor = {}
function aactor.get(Module)
	return {
		name = 'aactor',
		command_name = 'UEActor',
		command_description = 'Insert an AActor header snippet',
		arguments = {
			params = {
				default = nil,
				string_parse_function = Module.snippets.parse_macro_parameters_snippet,
			},
			parents = {
				default = 'AActor',
				string_parse_function = Module.utils.parse_comma_seperated,
			},
		},
		build_table = function(Module, arg_table)
			return {
				'UCLASS(' .. Module.snippets.generate_macro_parameters_snippet(Module, arg_table.params) .. ')',
				'class A' .. arg_table._name .. Module.snippets.generate_parent_classes_snippet(Module, arg_table.parents),
				'{',
				'\tGENERATED_BODY()',
				'',
				'public:',
				'\tA' .. arg_table.name .. '();',
				'};',
				'',
			}
		end,
		apply_tab_string = function(Module, tab_string, build_table)
			for index, value in ipairs(build_table) do
				if index ~=5 and index ~=9 then
					build_table[index] = tab_string .. value
				end
			end
		end,
	}
end

--- Return Module
return aactor
