--- Initialise Module
local nvim_ue5 = {}

--- Includes
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
nvim_ue5.log = require("nvim-ue5.log")
nvim_ue5.highlights = require("nvim-ue5.highlights")

--- Include Modules that have commands, used in the command module to bind and unbind commands
nvim_ue5.command_modules = {
	nvim_ue5.clean,
	nvim_ue5.generate,
	nvim_ue5.clangd,
	nvim_ue5.compile_commands,
	nvim_ue5.headers,
	nvim_ue5.build,
	nvim_ue5.info,
	nvim_ue5.snippets,
}

--- Variables
nvim_ue5.loaded = false

--- Setup
function nvim_ue5.setup(options)
	--- Setup Config
	nvim_ue5.config.setup(options)
	--- Initialise commands
	nvim_ue5.commands.init(nvim_ue5)
	--- Initialise highlights
	nvim_ue5.highlights.create_ns_id(nvim_ue5)
	nvim_ue5.highlights.create_groups(Module)
end

--- Called when VimEnter or DirChanged
function nvim_ue5.scan()
	--- Reset project config
	nvim_ue5.config.reset_project()

	--- Variables
	local project_config = nil
	local finished = false
	
	--- Initialise file handle, using the current directory
	local handle = vim.loop.fs_scandir(vim.loop.cwd())
	if handle then
		repeat
			--- Get the next file/directory
			local file_name, file_type = vim.loop.fs_scandir_next(handle)

			--- If we can't get anything, then we are finished, and can exit
			if not file_name then
				finished = true
			--- FILE
			elseif file_type == "file" then
				--- We are looking for a .uproject file so we can get the name of the project
				local uproject_match_pos = vim.regex('.uproject$'):match_str(file_name)
				if uproject_match_pos then
					nvim_ue5.config.project['project_name'] = file_name:sub(1, uproject_match_pos) --- Setting the project name
				elseif file_name == "project_config.lua" then
					project_config = dofile(vim.loop.cwd() .. "/project_config.lua") --- Setting the project config
				end
			--- DIRECTORY and its the Source directory (we want to get all the module names)
			elseif file_type == "directory" and file_name == "Source" then
				--- Variables
				local source_finished = false
				
				--- File Handle
				local source_handle = vim.loop.fs_scandir(file_name)
				if source_handle then
					repeat
						local source_file_name, source_file_type = vim.loop.fs_scandir_next(source_handle)
						--- Can't get anything, so we are finished
						if not source_file_name then
							source_finished = true
						--- We've found a directory, so its name is a module name, so we add it to our table of module names
						elseif source_file_type == "directory" then
							table.insert(nvim_ue5.config.project['module_names'], #nvim_ue5.config.project['module_names']+1, source_file_name)
						end
					until source_finished
				end
			end
		until finished
	end

	--- We've found a project config, so we know that this is a valid ue5 project
	if project_config then
		nvim_ue5.config.setup_project(project_config)
		nvim_ue5.commands.bind(nvim_ue5)
		nvim_ue5.loaded = true
	--- We haven't found a project config, so this isn't a valid ue5 project
	elseif nvim_ue5.config.project['project_name'] == '' and nvim_ue5.loaded == true then
		--- Unbind commands and set project to false, just in case we were previously initialised
		nvim_ue5.commands.unbind(nvim_ue5)
		nvim_ue5.loaded = false
	end
end

--- Return Module
return nvim_ue5
