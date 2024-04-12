local snippets = {}

local utils = require('nvim-ue5.utils')

function snippets.parse_macro_arguments(arguments)
	local arguments_string = ""
	local first_arg = true
	
	for key, value in pairs(arguments) do
		local argument_string = ""

		if type(key) == "number" then
			argument_string = value
		elseif type(key) == "string" then
			argument_string = key .. '='
			if type(value) == "string" then
				argument_string = argument_string .. value
			elseif type(value) == "table" then
				argument_string = argument_string .. '('
				argument_string = argument_string .. snippets.parse_macro_arguments(value)
				argument_string = argument_string .. ')'
			end
		end
		
		if first_arg then
			arguments_string = arguments_string .. argument_string
			first_arg = false
		else
			arguments_string = arguments_string .. ', ' .. argument_string
		end
	end
	
	return arguments_string
end

function snippets.parse_macro_arguments_string(arguments_string)
	local comma_seperated_elements = utils.parse_comma_seperated(arguments_string)

	local arguments = {}
	for index, element in ipairs(comma_seperated_elements) do
		if string.find(element, '=') then
			local key, value = string.match(element, "([^=]+)=(.+)")
			local inner = string.match(value, '%((.-)%)')
			if inner then
				arguments[key] = {}
				local inner_elements = {}
				for inner_element in inner:gmatch('([^,]+)') do
					table.insert(inner_elements, inner_element)
				end
				for inner_index, inner_element in ipairs(inner_elements) do
					if string.find(inner_element, '=') then
						local inner_key, inner_value = string.match(inner_element, '([^=]+)=(.+)')
						arguments[key][inner_key] = inner_value
					else
						arguments[key][inner_index] = inner_element
					end
				end
			end
		else
			arguments[index] = element
		end
	end
	
	return arguments
end

function snippets.parse_parent_classes(parent_classes)
	if #parent_classes > 0 then
		local parents_string = ' : public '
		local first = true
		for _, value in ipairs(parent_classes) do
			if first then
				parents_string = parents_string .. value
				first = false
			else
				parents_string = parents_string .. ', ' .. value
			end
		end
		return parents_string
	end

	return ''
end

function snippets.generate_class(class_name, uclass_arguments, parent_classes)
	local tabs_string = utils.get_tabs_string()

	local text = {
		tabs_string .. 'UCLASS(' .. snippets.parse_macro_arguments(uclass_arguments) .. ')',
		tabs_string .. 'class U' .. class_name .. snippets.parse_parent_classes(parent_classes),
		tabs_string .. '{',
		tabs_string .. '\tGENERATED_BODY()',
		'',
		tabs_string .. 'public:',
		tabs_string .. '\tU' .. class_name .. '();',
		tabs_string .. '};',
		'',
	}

	utils.write_to_current_buffer_line(text)
end

function snippets.generate_struct(struct_name, ustruct_arguments, parent_structs)
	local tabs_string = utils.get_tabs_string()

	local text = {
		tabs_string .. 'USTRUCT(' .. snippets.parse_macro_arguments(ustruct_arguments) .. ')',
		tabs_string .. 'struct F' .. struct_name .. snippets.parse_parent_classes(parent_structs),
		tabs_string .. '{',
		tabs_string .. '\tGENERATED_BODY()',
		'',
		tabs_string .. '};',
		'',
	}

	utils.write_to_current_buffer_line(text)
end

function snippets.generate_interface(interface_name, uinterface_arguments, uinterface_parents, iinterface_parents)
	local tabs_string = utils.get_tabs_string()

	local text = {
		tabs_string .. 'UINTERFACE(' .. snippets.parse_macro_arguments(uinterface_arguments) .. ')',
		tabs_string .. 'class U' .. interface_name .. snippets.parse_parent_classes(uinterface_parents),
		tabs_string .. '{',
		tabs_string .. '\tGENERATED_UINTERFACE_BODY()',
		tabs_string .. '};',
		'',
		tabs_string .. 'class I' .. interface_name .. snippets.parse_parent_classes(iinterface_parents),
		tabs_string .. '{',
		tabs_string .. '\tGENERATED_IINTERFACE_BODY()',
		'',
		tabs_string .. '};',
		'',
	}

	utils.write_to_current_buffer_line(text)
end

function snippets.generate_actor(actor_name, uclass_arguments, parent_classes)
	local tabs_string = utils.get_tabs_string()

	local text = {
		tabs_string .. 'UCLASS(' .. snippets.parse_macro_arguments(uclass_arguments) .. ')',
		tabs_string .. 'class A' .. actor_name .. snippets.parse_parent_classes(parent_structs),
		tabs-string .. '{',
		tabs_string .. '\tGENERATED_BODY()',
		'',
		tabs_string .. '};',
		'',
	}

	utils.write_to_current_buffer_line(text)
end

return snippets
