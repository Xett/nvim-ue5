--- Initialise Module
local clean = {}

--- Bind Commands
function clean.bind(Module)
	vim.api.nvim_create_user_command('UEClean',
		function(opts)
			Module.clean.clean(Module)
		end,
		{
			desc="Cleans the directory, according to the clean map config",			
		})
end

--- Unbind Commands
function clean.unbind(Module)
	vim.api.nvim_del_user_command('UEClean')
end

--- Check if the file is in the whitelist (do NOT clean)
function clean.is_file_in_whitelist(file_path, whitelist)
	--- Gets the file name from the path, matches one or more characters at the end, except for a /
	local file_pattern = vim.regex('[^/]+$')
	--- Use our regex to get the file name from the file path
	local file = vim.fn.matchstr('[^/]+$', file_path)

	--- Check if the file name is in the whitelist
	for _,entry in ipairs(whitelist) do
		local result = vim.fn.matchstr(entry, file)
		local matches = result ~= ""
		if matches then
			return true
		end
	end

	return false
end

--- Return the plugin config given the plugin name, if it isn't found we just return the default plugins
function clean.get_plugin_config(plugin_name, plugins_config)
	for plugin_dir, config in pairs(plugins_config) do
		if plugin_dir == plugin_name then
			return config
		end
	end
	return plugins_config['default']
end

--- Delete all files in a directory (recursive). Ignores files in the whitelist
function clean.delete_all_mode(Module, path, whitelist, recursive)
	local handle = vim.loop.fs_scandir(path)
	if handle then
		repeat
			local name, file_type = vim.loop.fs_scandir_next(handle)
			--- We scan all the files in the directory, if the name is nil we have reached the end
			--- TODO: double check this is the right way, since we are using a handle already, is this even needed?
			if name == nil then
				return
			end

			local file_path = path .. '/' .. name
			--- If the file is NOT a directory and is NOT in the whitelist, we want to delete it
			if file_type ~= "directory" and not clean.is_file_in_whitelist(file_path, whitelist) then
				--- Log that we are deleting the file
				local log_string = "\t\tDeleting " .. file_path
				Module.log.write(Module, {log_string})
				local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
				Module.highlights.highlight_paths(Module, log_string, num_lines)
				
				--- Actually delete the file
				os.remove(file_path)

			--- If the file is a directory and we want to recursively delete all, call this function on that directory too
			elseif file_type == "directory" and recursive then
				clean.delete_all_mode(Module, file_path, whitelist, recursive)
			end
		until not handle 
	end
end

--- Delete a list of specific files, and checks the whitelist
function clean.delete_specific_mode(Module, path, whitelist, files_to_delete)
	for _,whitelist_entry in ipairs(files_to_delete) do
		local file_path = path .. '/' .. whitelist_entry
		if not clean.is_file_in_whitelist(file_path, whitelist) then
			local success, err_msg = os.remove(file_path)
			--- Log if delete was successful
			if success then
				local log_string = "\t\tDeleting ".. whitelist_entry
				Module.log.write(Module, {log_string})
				local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
				Module.highlights.highlight_paths(Module, log_string, num_lines)

			--- Log if the delete failed
			else
				local log_string = "\t\t Failed to delete " .. whitelist_entry
				Module.log.write(Module, {log_string})
				local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
				Module.highlights.highlight_fail(Module, num_lines)
				Module.highlights.highlight_paths(Module, log_string, num_lines)
			end
		end
	end
end

--- Clean a directory given a path to it
function clean.clean_dir(Module, path, config, recursive)
	--- Recursive defaults to true
	if recursive == nil then
		recursive = true
	end

	--- Log that we are cleaning the path
	local log_string = "Cleaning " .. path
	Module.log.write(Module, {log_string})
	local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
	Module.highlights.highlight_paths(Module, log_string, num_lines)
	
	--- Delete all
	if config.mode=="delete_all" then
		--- Log what mode we are using
		Module.log.write(Module, {"\tMode is Delete All"})
		local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
		Module.highlights.highlight_line(Module, 'UE5CleaningModeAll', num_lines)
		
		--- Call the actual mode function
		clean.delete_all_mode(Module, path, config.whitelist_files, recursive)
	
	--- Delete specific
	elseif config.mode=="delete_specific" then
		--- Log what mode we are using
		Module.log.write(Module, {"\tMode is Delete Specific"})
		local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
		Module.highlights.highlight_line(Module, 'UE5CleaningModeSpecific', num_lines)
		
		--- Call the actual mode function
		clean.delete_specific_mode(Module, path, config.whitelist_files, config.files_to_delete)
	end
end

--- The actual function called, to clean
function clean.clean(Module)
	--- Variables
	local clean_map = Module.config.project.config['clean_map']
	
	--- Ensure that the log window is open
	Module.log.open(Module)

	Module.log.write(Module, {"Cleaning project directory..."})
	
	--- Iterate through the cleaning map
	for dir, config in pairs(clean_map) do
		--- root needs to be handled differently to everything else
		if dir == "root" then
			local root_path_abs = vim.loop.cwd()
			clean.clean_dir(Module, root_path_abs, config, false)

		--- Plugins needs to be handled differently to everything else
		elseif dir == "Plugins" then
			local plugins_path_abs = vim.loop.cwd() .. '/Plugins'
			--- Iterate through all directories in /Plugins
			local plugins_dir_handle = vim.loop.fs_scandir(plugins_path_abs)
			if plugins_dir_handle then
				repeat
					local dir_name, file_type = vim.loop.fs_scandir_next(plugins_dir_handle)

					--- Make sure that we actually have a dir_name, if it is nil we have reached the end of the directory
					if dir_name == nil then
						return
					end

					--- We only care about directories
					if dir_name and file_type == "directory" then
						--- Get the plugin clean config (if there isn't one, we just get a default plugin conf)
						local plugin_config = clean.get_plugin_config(dir_name, config)
						
						--- Iterate through the plugin config, which holds the local plugin path and its config.
						for plugin_dir, dir_config in pairs(plugin_config) do
							--- Build the absolute plugin path
							local plugin_dir_path = plugins_path_abs .. '/' .. dir_name
							
							--- We ignore the "root" plugin conf, since it is specifically handled
							if plugin_dir ~= "root" then
								plugin_dir_path = plugin_dir_path .. '/' .. plugin_dir
							end
							
							--- Call clean directory on the plugin path, passing in its config
							clean.clean_dir(Module, plugin_dir_path, dir_config)
						end
					end
				until not plugins_dir_handle
			end
		else
			--- Clean the directory
			clean.clean_dir(Module, vim.loop.cwd() .. "/" .. dir, config)
		end
	end
end

--- Return Module
return clean
