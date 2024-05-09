local bot_buf = {}

bot_buf.id = nil

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
	end
end

function bot_buf.write(Module, text)
	if Module.bot_buf.id == nil then
		Module.bot_buf.open(Module)
	end

	vim.api.nvim_buf_set_lines(Module.bot_buf.id, 0, -1, false, text)
end

function bot_buf.append(Module, text)
	if Module.bot_buf.id == nil then
		Module.bot_buf.open(Module)
	end

	vim.api.nvim_buf_set_lines(Module.bot_buf.id, -1, -1, false, text)
end

return bot_buf
