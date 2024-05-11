local bot_buf = {}

bot_buf.id = nil
bot_buf.first_line_written = false

function close_bot_buf(bot_buf_id, window_id)
	if not bot_buf.id == vim.api.nvim_get_current_buf() then
		return
	end
	vim.api.nvim_win_close(window_id, true)
end

function bot_buf.bind(Module)
	Module.bot_buf.augroup = vim.api.nvim_create_augroup("nvim-ue5.bot_buf", {})

	vim.api.nvim_set_keymap('n', 'q', '<cmd> lua close_bot_buf(' .. Module.bot_buf.id .. ', ' .. Module.bot_buf.get_window_id(Module) .. ') <CR>', {noremap=true, silent=true})

	Module.bot_buf.quit_command_id = vim.api.nvim_create_autocmd({"BufLeave"}, {
		group = Module.bot_buf.augroup,
		pattern = "*",
		callback = function(ev)
			if not vim.api.nvim_get_current_buf() == Module.bot_buf.id then
				return
			end

			Module.bot_buf.unbind(Module)
		end
	})
end

function bot_buf.unbind(Module)
	vim.api.nvim_del_autocmd(Module.bot_buf.quit_command_id)	
end

function bot_buf.is_open(Module)
	if Module.bot_buf.id == nil then
		return false
	end

	local win_list = vim.api.nvim_list_wins()
	for _,win in ipairs(win_list) do
		if vim.api.nvim_win_get_buf(win) == Module.bot_buf.id then
			return true
		end
	end
end

function bot_buf.get_window_id(Module)
	local win_list = vim.api.nvim_list_wins()
	for _,win in ipairs(win_list) do
		if vim.api.nvim_win_get_buf(win) == Module.bot_buf.id then
			return win
		end
	end
	return nil
end

function bot_buf.open(Module)
	if Module.bot_buf.id == nil then
		Module.bot_buf.id = vim.api.nvim_create_buf(false, true)

		vim.api.nvim_buf_set_option(Module.bot_buf.id, 'buftype', 'nofile')

		vim.api.nvim_buf_set_lines(Module.bot_buf.id, 0, -1, false, {""})
	end

	if not Module.bot_buf.is_open(Module) then
		vim.cmd('botright sb' .. Module.bot_buf.id)
		local win_id = Module.bot_buf.get_window_id(Module)
		vim.api.nvim_win_set_option(win_id, 'number', false)
		vim.api.nvim_win_set_option(win_id, 'statusline', 'Press q to quit')

		Module.bot_buf.bind(Module)
	end
end

function bot_buf.clear(Module)
	if not Module.bot_buf.is_open(Module) then
		Module.bot_buf.open(Module)
	end

	vim.api.nvim_buf_set_lines(Module.bot_buf.id, 0, -1, false, {""})
	Module.bot_buf.first_line_written = false
end

function bot_buf.write(Module, text)
	if Module.bot_buf.is_open(Module) then
		Module.bot_buf.open(Module)
	end

	if not Module.bot_buf.first_line_written then
		vim.api.nvim_buf_set_lines(Module.bot_buf.id, 0, -1, false, text)
		Module.bot_buf.first_line_written = true
	else
		vim.api.nvim_buf_set_lines(Module.bot_buf.id, -1, -1, false, text)
	end
end

return bot_buf
