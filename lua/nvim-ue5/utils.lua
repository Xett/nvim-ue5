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
	local tabstop = vim.api.nvim_bug_get_option(0, 'tabstop')
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

function utils.is_bottom_buffer_open(Module)
	if Module.bottom_buffer_id == nil then
		return false
	end

	local win_list = vim.api.nvim_list_wins()
	for _, win in ipairs(win_list) do
		if vim.api.nvim_win_get_buf(win) == Module.bottom_buffer_id then
			return true
		end
	end

	return false
end

function utils.get_bottom_buffer_window_num(Module)
	---if Module.utils.is_bottom_buffer_open(Module) then
		local win_list = vim.api.nvim_list_wins()
		for _, win in ipairs(win_list) do
			if vim.api.nvim_win_get_buf(win) == Module.bottom_buffer_id then
				return win
			end
		end
	---end
	return nil
end

function utils.open_bottom_buffer(Module)
	if Module.bottom_buffer_id == nil then
		Module.bottom_buffer_id = vim.api.nvim_create_buf(false, true)
	
		vim.api.nvim_buf_set_option(Module.bottom_buffer_id, 'buftype', 'nofile')
		---vim.api.nvim_buf_set_option(Module.bottom_buffer_id, 'bufhidden', 'wipe')
		---vim.api.nvim_buf_set_option(Module.bottom_buffer_id, 'modifiable', false)
		---vim.api.nvim_buf_set_option(Module.bottom_buffer_id, 'readonly', true)
		
		vim.api.nvim_buf_set_lines(Module.bottom_buffer_id, 0, -1, false, {""})
	end

	if not Module.utils.is_bottom_buffer_open(Module) then
		vim.cmd('botright sb' .. Module.bottom_buffer_id)
		local win_id = Module.utils.get_bottom_buffer_window_num(Module)
		---if not win_id == nil then	
			vim.api.nvim_win_set_option(win_id, 'number', false)
		---end
	end
end

function utils.write_to_bottom_buffer(Module, text)
	if Module.bottom_buffer_id == nil then
		Module.utils.open_bottom_buffer(Module)
	end

	vim.api.nvim_buf_set_lines(Module.bottom_buffer_id, 0, -1, false, text)
end

function utils.append_to_bottom_buffer(Module, text)
	if Module.bottom_buffer_id == nil then
		Module.utils.open_bottom_buffer(Module)
	end

	vim.api.nvim_buf_set_lines(Module.bottom_buffer_id, -1, -1, false, text)
end

return utils
