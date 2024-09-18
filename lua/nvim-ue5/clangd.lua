--- Initialise Module
local clangd = {}

--- Bind Commands
function clangd.bind(Module)
	vim.api.nvim_create_user_command('UEGenerateClangd',
		function(opts)
			Module.clangd.create_clangd_file(Module)
		end,
		{
			desc="Generate the .clangd file, requires the project to be generated for vscode",	
		})
end

--- Unbind Commands
function clangd.unbind(Module)
	vim.api.nvim_del_user_command('UEGenerateClangd')
end


--- Add a debug flag
function clangd.add_debug_flag(Module, clangd_file, debug_flag)
	clangd_file:write('\t\t"-D' .. debug_flag .. '",\n')
	Module.log.write(Module, {"Flag:\t\t\t" .. debug_flag})
end

--- Add an engine include path
function clangd.add_engine_include_path(Module, clangd_file, unreal_engine_path, secondary_path)
	clangd_file:write('\t\t"-I' .. unreal_engine_path .. secondary_path .. '",\n')
	local string = "Engine Include:\t\t" .. unreal_engine_path .. secondary_path
	Module.log.write(Module, {string})
	local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
	Module.highlights.highlight_paths(Module, string, num_lines)
end

--- Add a project include path
function clangd.add_project_include_path(Module, clangd_file, module_name)
	clangd_file:write('\t\t"-I' .. vim.loop.cwd() .. '/Intermediate/Build/Linux/UnrealEditor/Inc/' .. module_name .. '/UHT",\n')
	local string = "Project Include:\t" .. vim.loop.cwd() .. '/Intermediate/Build/Linux/UnrealEditor/Inc/' .. module_name .. '/UHT'
	Module.log.write(Module, {string})
	local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
	Module.highlights.highlight_paths(Module, string, num_lines)
end

--- Create the .clangd file
function clangd.create_clangd_file(Module)
	--- Variables
	local options = Module.config.options
	local project_config = Module.config.project['config']
	local clangd_options = project_config.clangd
	local debug_flags = clangd_options.debug_flags
	local project_modules = Module.config.project['module_names']
	local clangd_file = io.open(vim.loop.cwd() .. "/.clangd", "w")

	--- Ensure the log window is open
	Module.log.open(Module)

	Module.log.write(Module, {"Generating .clangd file"})

	--- If the .clangd file write handler is valid, we can write to it (duhh)
	if clangd_file then
		--- Compile flags
		clangd_file:write('CompileFlags:\n')
		clangd_file:write('\tAdd: [\n')
		for _,debug_flag in ipairs(debug_flags) do
			clangd.add_debug_flag(Module, clangd_file, debug_flag)
		end

		--- Engine includes
		clangd.add_engine_include_path(Module, clangd_file, options['unreal_engine_path'], '/Engine/Source/Runtime/Core/Public')
		clangd.add_engine_include_path(Module, clangd_file, options['unreal_engine_path'], '/Engine/Source/Runtime/Core/Private')
		clangd.add_engine_include_path(Module, clangd_file, options['unreal_engine_path'], '/Engine/Source/Runtime/Engine/Classes')
		clangd.add_engine_include_path(Module, clangd_file, options['unreal_engine_path'], '/Engine/Source/Runtime/Engine/Public')
		clangd.add_engine_include_path(Module, clangd_file, options['unreal_engine_path'], '/Engine/Source/Runtime/Engine/Private')
		
		--- Project includes (each project module)
		for _,module_name in ipairs(project_modules) do
			clangd.add_project_include_path(Module, clangd_file, module_name)
		end

		--- Close off
		clangd_file:write('\t]')
		clangd_file:close()

		--- Log that we are done
		Module.log.write(Module, {"Finished..."})
		local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
		Module.highlights.highlight_success(Module, num_lines)
	end


end

--- Return Module
return clangd
