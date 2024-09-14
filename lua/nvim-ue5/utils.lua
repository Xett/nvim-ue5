local utils = {}

function utils.get_current_platform()
	local os_name = vim.loop.os_uname().sysname
	if os_name == "Windows" then
		return "Win64"
	elseif os_name == "Linux" then
		return "Linux"
	end
	return nil
end

function utils.get_build_script_path(options)
	local os_name = vim.loop.os_uname().sysname
	if os_name == "Windows" then
		return options['unreal_engine_path'] .. '/Engine/Build/BatchFiles/Build.bat'
	elseif os_name == "Linux" then
		return options['unreal_engine_path'] .. '/Engine/Build/BatchFiles/Linux/Build.sh'
	end
	return nil
end

function utils.get_generated_script_path(options)
	local os_name = vim.loop.os_uname().sysname
	if os_name == "Windows" then
		return options['unreal_engine_path'] .. '/GenerateProjectFiles.bat'
	elseif os_name == "Linux" then
		return options['unreal_engine_path'] .. '/GenerateProjectFiles.sh'
	end
	return nil
end

function utils.jobstart_on_exit_out_write(messages)
	return function(job_id, code, event)
		if event == 'exit' and code == 0 then
			vim.api.nvim_out_write(messages['success'])
		else
			vim.api.nvim_out_write(messages['fail'])
		end
	end
end

function utils.async_command_with_output(command_string, messages)
	vim.fn.jobstart(
		command_string,
		{
			on_exit = utils.jobstart_on_exit_out_write(messages),
		}
	)
end

function utils.parse_comma_seperated(string)
	local comma_seperated_elements = {}

	for element in string:gmatch('([^,]+)') do
		table.insert(comma_seperated_elements, element)
	end

	return comma_seperated_elements
end

function utils.write_to_current_buffer_line(text)
	local current_line = vim.fn.line('.')
	vim.api.nvim_buf_set_lines(0, current_line, current_line, false, text)
end

function utils.get_tabs_string()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local tabstop = vim.api.nvim_buf_get_option(0, 'tabstop')
	local virtrow = cursor_pos[1]
	local virtcol = cursor_pos[2]

	local line = vim.api.nvim_buf_get_lines(0, virtrow - 1, virtrow, false)[1]
	local text_before_cursor = string.sub(line, 1, virtcol - 1)

	local _, num_tabs = text_before_cursor:gsub('\t', '')

	local spaces_to_tabs = math.floor((virtcol - num_tabs) / tabstop)
	if spaces_to_tabs < 0 then
		spaces_to_tabs = 0
	end
	local tabs_to_cursor = spaces_to_tabs + num_tabs

	local tabs_string = ''
	for i = 1, tabs_to_cursor do
		tabs_string = tabs_string .. '\t'
	end

	return tabs_string
end

function utils.module_name_is_valid(Module, module_name)
	for _, element in ipairs(Module.config.project.module_names) do
		if string.lower(element) == string.lower(module_name) then
			return true
		end
	end

	return false
end

function utils.target_is_valid(Module, target)
	for _, element in ipairs(Module.config.project.build_targets) do
		if string.lower(element) == string.lower(target) then
			return true
		end
	end

	return false
end

function utils.target_type_is_valid(Module, target_type)
	for _, element in ipairs(Module.config.project.build_target_types) do
		if string.lower(element) == string.lower(target_type) then
			return true
		end
	end

	return false
end

function utils.platform_is_valid(Module, platform)
	for _, element in ipairs(Module.config.project.platforms) do
		if string.lower(element) == string.lower(platform) then
			return true
		end
	end

	return false
end

return utils
