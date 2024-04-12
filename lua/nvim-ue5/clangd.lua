local clangd = {}

function clangd.add_debug_flag(clangd_file, debug_flag)
	clangd_file:write('\t\t"-D' .. debug_flag .. '",\n')
end

function clangd.add_engine_include_path(clangd_file, unreal_engine_path, secondary_path)
	clangd_file:write('\t\t"-I' .. unreal_engine_path .. secondary_path .. '",\n')
end

function clangd.add_project_include_path(clangd_file, module_name)
	clangd_file:write('\t\t"-I' .. vim.loop.cwd() .. '/Intermediate/Build/Linux/UnrealEditor/Inc/' .. module_name .. '/UHT",\n')
end

function clangd.create_clangd_file(options, clangd_options, project_modules)
	local clangd_file = io.open(vim.loop.cwd() .. "/.clangd", "w")

	if clangd_file then
		clangd_file:write('CompileFlags:\n')
		clangd_file:write('\tAdd: [\n')
		for debug_flag in clangd_options['debug_flags'] do
			clangd.add_debug_flag(clangd_file, debug_flag)
		end
		clangd.add_engine_include_path(clangd_file, options['unreal_engine_path'], '/Engine/Source/Runtime/Core/Public')
		clangd.add_engine_include_path(clangd_file, options['unreal_engine_path'], '/Engine/Source/Runtime/Core/Private')
		clangd.add_engine_include_path(clangd_file, options['unreal_engine_path'], '/Engine/Source/Runtime/Engine/Classes')
		clangd.add_engine_include_path(clangd_file, options['unreal_engine_path'], '/Engine/Source/Runtime/Engine/Public')
		clangd.add_engine_include_path(clangd_file, options['unreal_engine_path'], '/Engine/Source/Runtime/Engine/Private')
		for module_name in project_modules do
			clangd.add_project_include_path(clangd_file, module_name)
		end
		clangd_file:write('\t]')
		clangd_file:close()
	end


end

return clangd
