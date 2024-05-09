local nvim_ue5 = {}

nvim_ue5.config = require("nvim-ue5.config")

nvim_ue5.clean = require("nvim-ue5.clean")
nvim_ue5.generate = require("nvim-ue5.generate")
nvim_ue5.clangd = require("nvim-ue5.clangd")
nvim_ue5.compile_commands = require("nvim-ue5.compile_commands")
nvim_ue5.headers = require("nvim-ue5.headers")
nvim_ue5.build = require("nvim-ue5.build")

nvim_ue5.info = require("nvim-ue5.info")

nvim_ue5.snippets = require("nvim-ue5.snippets")

nvim_ue5.commands = require("nvim-ue5.commands")

nvim_ue5.utils = require("nvim-ue5.utils")

nvim_ue5.loaded = false

nvim_ue5.bottom_buffer_id = nil

function nvim_ue5.setup(options)
	nvim_ue5.config.setup(options)
	nvim_ue5.commands.init(nvim_ue5)
end

function nvim_ue5.scan()
	nvim_ue5.config.reset_project()
	local project_config = nil
	local handle = vim.loop.fs_scandir(vim.loop.cwd())
	local finished = false
	if handle then
		repeat
			local file_name, file_type = vim.loop.fs_scandir_next(handle)
			if not file_name then
				finished = true
			elseif file_type == "file" then
				local uproject_match_pos = vim.regex('.uproject$'):match_str(file_name)
				if uproject_match_pos then
					nvim_ue5.config.project['project_name'] = file_name:sub(1, uproject_match_pos)
				elseif file_name == "project_config.lua" then
					project_config = dofile(vim.loop.cwd() .. "/project_config.lua")
				end
			elseif file_type == "directory" and file_name == "Source" then
				local source_handle = vim.loop.fs_scandir(file_name)
				local source_finished = false
				if source_handle then
					repeat
						local source_file_name, source_file_type = vim.loop.fs_scandir_next(source_handle)
						if not source_file_name then
							source_finished = true
						elseif source_file_type == "directory" then
							table.insert(nvim_ue5.config.project['module_names'], #nvim_ue5.config.project['module_names']+1, source_file_name)
						end
					until source_finished
				end
			end
		until finished
	end
	if project_config then
		nvim_ue5.config.setup_project(project_config)
		nvim_ue5.commands.bind(nvim_ue5)
		nvim_ue5.loaded = true
	elseif nvim_ue5.config.project['project_name'] == '' and nvim_ue5.loaded == true then
		nvim_ue5.commands.unbind(nvim_ue5)
		nvim_ue5.loaded = false
	end
end

return nvim_ue5
