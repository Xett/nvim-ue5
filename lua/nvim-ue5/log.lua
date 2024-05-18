local log = {}

log.id = nil
log.first_line_written = false

function close_log(log_id, window_id)
	if not log.id == vim.api.nvim_get_current_buf() then
		return
	end
	vim.api.nvim_win_close(window_id, true)
end

function log.bind(Module)
	Module.log.augroup = vim.api.nvim_create_augroup("nvim-ue5.log", {})

	vim.api.nvim_set_keymap('n', 'q', '<cmd> lua close_log(' .. Module.log.id .. ', ' .. Module.log.get_window_id(Module) .. ') <CR>', {noremap=true, silent=true})

	Module.log.quit_command_id = vim.api.nvim_create_autocmd({"BufLeave"}, {
		group = Module.log.augroup,
		pattern = "*",
		callback = function(ev)
			if not vim.api.nvim_get_current_buf() == Module.log.id then
				return
			end

			Module.log.unbind(Module)
		end
	})
end

function log.unbind(Module)
	vim.api.nvim_del_autocmd(Module.log.quit_command_id)	
end

function log.is_open(Module)
	if Module.log.id == nil then
		return false
	end

	local win_list = vim.api.nvim_list_wins()
	for _,win in ipairs(win_list) do
		if vim.api.nvim_win_get_buf(win) == Module.log.id then
			return true
		end
	end
end

function log.get_window_id(Module)
	local win_list = vim.api.nvim_list_wins()
	for _,win in ipairs(win_list) do
		if vim.api.nvim_win_get_buf(win) == Module.log.id then
			return win
		end
	end
	return nil
end

function log.open(Module)
	if Module.log.id == nil then
		Module.log.id = vim.api.nvim_create_buf(false, true)

		vim.api.nvim_buf_set_option(Module.log.id, 'buftype', 'nofile')

		vim.api.nvim_buf_set_lines(Module.log.id, 0, -1, false, {""})
	end

	if not Module.log.is_open(Module) then
		vim.cmd('botright sb' .. Module.log.id)
		local win_id = Module.log.get_window_id(Module)
		vim.api.nvim_win_set_option(win_id, 'number', false)
		vim.api.nvim_win_set_option(win_id, 'statusline', 'Press q to quit')

		Module.log.bind(Module)
	end
end

function log.clear(Module)
	if not Module.log.is_open(Module) then
		Module.log.open(Module)
	end

	vim.api.nvim_buf_set_lines(Module.log.id, 0, -1, false, {""})
	Module.log.first_line_written = false
end

function log.write(Module, text)
	if Module.log.is_open(Module) then
		Module.log.open(Module)
	end

	if not Module.log.first_line_written then
		vim.api.nvim_buf_set_lines(Module.log.id, 0, -1, false, text)
		Module.log.first_line_written = true
	else
		vim.api.nvim_buf_set_lines(Module.log.id, -1, -1, false, text)
	end
end

return log
