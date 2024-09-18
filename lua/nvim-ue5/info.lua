--- Initialise Module
local info = {}

--- Variables
info.win_id = nil
info.last_win_id = nil

--- Bind Commands
function info.bind(Module)
	vim.api.nvim_create_user_command('UEInfo',
		function(opts)
			Module.info.toggle_window(Module)
		end,
		{
			desc="Displays plugin information such as the Engine Path, the Project Name, Module Names and Build Targets",	
		}
	)
end

--- Unbind Commands
function info.unbind(Module)
	vim.api.nvim_del_user_command('UEInfo')
end

--- Create the Info Window
function info.create_window(Module)	
	--- Variables
	local height = 20
	local width = 50 --- Make these configurable?
	
	info.last_win_id = vim.api.nvim_get_current_win()
	local buffer_number = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buffer_number, 0, -1, false, {})

	local module_names = ""
	for _, module_name in pairs(Module.config.project.module_names) do
		module_names = module_names .. module_name .. " "
	end

	local build_targets = ""
	for _, build_target in pairs(Module.config.project.build_targets) do
		build_targets = build_targets .. build_target .. " "
	end

	local content = {
		"",
		"   Unreal Engine Path:             " .. Module.config.options.unreal_engine_path,
		"   Project Name:                   " .. Module.config.project.project_name,
		"   Module Names:                   " .. module_names,
		"   Build Targets:                  " .. build_targets,
	}

	if #content[2] > 50 then
		width = #content[2] + 3
	end

	local title_text = "Unreal Engine Information"
	local title = {
		string.rep(" ", math.floor((width - #title_text) / 2)) .. title_text
	}
	
	vim.api.nvim_buf_set_lines(buffer_number, 0, -1, true, title)
	vim.api.nvim_buf_add_highlight(buffer_number, -1, "Title", 0, 0, width)
	vim.api.nvim_buf_set_lines(buffer_number, 1, -1, true, content)

	info.win_id = vim.api.nvim_open_win(buffer_number, false,
		{
			relative = 'editor',
			width = width,
			height = height,
			row = ( ( vim.o.lines / 2 ) - (6 + 2) ) / 2,
			col = ( vim.o.columns / 2 ) - 20,
			style = "minimal",
			border = "rounded",
		}
	)

	vim.api.nvim_set_current_win(info.win_id)

	--- Bind closing commands
	vim.api.nvim_buf_set_keymap(buffer_number, "n", "q", "<cmd>UEInfo<CR>", { silent=false })
	vim.api.nvim_buf_set_keymap(buffer_number, "n", "<Esc>", "<cmd>UEInfo<CR>", { silent=false })
	vim.api.nvim_buf_set_keymap(buffer_number, "n", "<CR>", "<cmd>UEInfo<CR>", { silent=false })
end

--- Close the Info Window
function info.close_window()
	vim.api.nvim_set_current_win(info.last_win_id)
	vim.api.nvim_win_close(info.win_id, true)
	info.win_id = nil
	info.last_win_id = nil
end

--- Toggle the Info Window
function info.toggle_window(Module)
	if info.win_id then
		info.close_window()
	else
		info.create_window(Module)
	end
end

--- Return Module
return info
