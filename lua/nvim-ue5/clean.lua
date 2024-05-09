local clean = {}

function clean.is_file_in_whitelist(file_path, whitelist)
	local file_pattern = vim.regex('[^/]+$')
	local file = vim.fn.matchstr('[^/]+$', file_path)

	for _,entry in ipairs(whitelist) do
		local result = vim.fn.matchstr(entry, file)
		local matches = result ~= ""
		if matches then
			return true
		end
	end

	return false
end

function clean.get_plugin_config(plugin_name, plugins_config)
	for plugin_dir, config in pairs(plugins_config) do
		if plugin_dir == plugin_name then
			return config
		end
	end
	return plugins_config['default']
end

function clean.delete_all_mode(Module, path, whitelist, recursive)
	local handle = vim.loop.fs_scandir(path)
	if handle then
		repeat
			local name, file_type = vim.loop.fs_scandir_next(handle)
			if name == nil then
				return
			end
			local file_path = path .. '/' .. name
			if file_type ~= "directory" and not clean.is_file_in_whitelist(file_path, whitelist) then
				Module.utils.append_to_bottom_buffer(Module, {"\t\tDeleting " .. file_path})
				os.remove(file_path)
			elseif file_type == "directory" and recursive then
				clean.delete_all_mode(Module, file_path, whitelist, recursive)
			end
		until not handle 
	end
end

function clean.delete_specific_mode(Module, path, whitelist, files_to_delete)
	for _,whitelist_entry in ipairs(files_to_delete) do
		local file_path = path .. '/' .. whitelist_entry
		if not clean.is_file_in_whitelist(file_path, whitelist) then
			local success, err_msg = os.remove(file_path)
			if success then
				Module.utils.append_to_bottom_buffer(Module, {"\t\tDeleting ".. whitelist_entry})
			end
		end
	end
end

function clean.clean_dir(Module, path, config, recursive)
	Module.utils.append_to_bottom_buffer(Module, {"Cleaning " .. path})
	if recursive == nil then
		recursive = true
	end
	if config.mode=="delete_all" then
		Module.utils.append_to_bottom_buffer(Module, {"\tMode is Delete All"})
		clean.delete_all_mode(Module, path, config.whitelist_files, recursive)
	elseif config.mode=="delete_specific" then
		Module.utils.append_to_bottom_buffer(Module, {"\tMode is Delete Specific"})
		clean.delete_specific_mode(Module, path, config.whitelist_files, config.files_to_delete)
	end
end

function clean.clean(Module)
	Module.utils.open_bottom_buffer(Module)
	Module.utils.write_to_bottom_buffer(Module, {"Cleaning project directory..."})
	local clean_map = Module.config.project.config['clean_map']
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
					if dir_name == nil then
						return
					end
					if dir_name and file_type == "directory" then
						local plugin_config = clean.get_plugin_config(dir_name, config)
						for plugin_dir, dir_config in pairs(plugin_config) do
							local plugin_dir_path = plugins_path_abs .. '/' .. dir_name
							if plugin_dir ~= "root" then
								plugin_dir_path = plugin_dir_path .. '/' .. plugin_dir
							end
							clean.clean_dir(Module, plugin_dir_path, dir_config)
						end
					end
				until not plugins_dir_handle
			end
		else
			clean.clean_dir(Module, vim.loop.cwd() .. "/" .. dir, config)
		end
	end
end

return clean
