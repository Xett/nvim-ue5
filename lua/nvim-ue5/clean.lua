local clean = {}

function clean.is_file_in_whitelist(file_path, whitelist)
	local file = vim.regex('[^/]+$'):match(file_path)

	for entry in whitelist do
		local pattern = vim.regex(entry)
		if pattern:match(file) then
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

function clean.delete_all_mode(path, whitelist, recursive)
	local handle = vim.loop.fs_scandir(path)
	if handle then
		repeat
			local name, file_type = vim.loop.fs_scandir_next(handle)
			local file_path = path .. '/' .. name
			if file_type ~= "directory" and not clean.is_file_in_whitelist(file_path, whitelist) then
				os.remove(file_path)
			elseif file_type == "directory" and recursive then
				clean.delete_all_mode(file_path, whitelist, recursive)
			end
		until not handle 
	end
end

function clean.delete_specific_mode(path, whitelist, files_to_delete)
	for entry in files_to_delete do
		local file_path = path .. '/' .. whitelist_entry
		if not clean.is_file_in_whitelist(file_path, whitelist) then
			os.remove(file_path)
		end
	end
end

function clean.clean_dir(path, config, recursive)
	if recursive == nil then
		recursive = true
	end
	if config.mode=="delete_all" then
		clean.delete_all_mode(path, config.whitelist_files, recursive)
	elseif config.mode=="delete_specific" then
		clean.delete_specific_mode(path, config.whitelist_files, config.files_to_delete)
	end
end

function clean.clean(clean_map)
	--- Iterate through the cleaning map
	for dir, config in pairs(clean_map) do
		--- root needs to be handled differently to everything else
		if dir == "root" then
			local root_path_abs = vim.loop.cwd()
			clean.clean_dir(root_path_abs, config, false)
			
		--- Plugins needs to be handled differently to everything else
		elseif dir == "Plugins" then
			local plugins_path_abs = vim.loop.cwd() .. '/Plugins'

			--- Iterate through all directories in /Plugins
			local plugins_dir_handle = vim.loop.fs_scandir(plugins_path_abs)
			if plugins_dir_handle then
				repeat
					local dir_name, file_type = vim.loop.fs_scandir_next(plugins_dir_handle)
					if dir_name and file_type == "directory" then
						local plugin_config = clean.get_plugin_config(dir_name, config)
						for plugin_dir, dir_config in pairs(plugin_config) do
							local plugin_dir_path = plugins_path_abs .. '/' .. dir_name
							if plugin_dir ~= "root" then
								plugin_dir_path = plugin_dir_path .. '/' .. plugin_dir
							end
							clean.clean_dir(plugin_dir_path, dir_config)
						end
					end
				until not plugins_dir_handle
			end
		else
			clean.clean_dir(vim.loop.cwd() .. "/" .. dir, config)
		end
	end
end

return M
