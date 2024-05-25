local compile_commands = {}

compile_commands.hl_namespace_id = nil

function compile_commands.bind(Module)
	vim.api.nvim_create_user_command('UEGenerateCompileCommands',
		function(opts)
			Module.compile_commands.build_compile_commands(Module)
		end,
		{
			desc="Generates compile_commands.json, requires that jq is installed, the project was generated with the VSCode option and that the Unreal Engine source has a compile_commands.json too.",	
		})
end

function compile_commands.unbind(Module)
	vim.api.nvim_del_user_command('UEGenerateCompileCommands')
end

function compile_commands.create_ns_id(Module)
	Module.compile_commands.hl_namespace_id = vim.api.nvim_create_namespace('nvim_ue5.compile_commands')
end

function compile_commands.create_highlight_groups(Module)
	vim.cmd('highlight UE5CompileCommandsPath ctermfg=18')
	vim.cmd('highlight UE5CompileCommandsSuccess ctermfg=Green')
	vim.cmd('highlight UE5CompileCommandsFail ctermfg=Red')
end

function compile_commands.get_engine_compile_commands_path(unreal_engine_path)
	return unreal_engine_path .. "/.vscode/compileCommands_UE5.json"
end

function compile_commands.get_project_compile_commands_path(project_name)
	return vim.loop.cwd() .. "/.vscode/compileCommands_" .. project_name .. ".json"
end

function compile_commands.get_output_path()
	return vim.loop.cwd() .. "/compile_commands.json"
end

function compile_commands.build_compile_commands(Module)
	if Module.compile_commands.hl_namespace_id == nil then
		Module.compile_commands.create_ns_id(Module)
		Module.compile_commands.create_highlight_groups(Module)
	end

	local options = Module.config.options
	local project_config = Module.config.project['config']
	local project_name = Module.config.project['project_name']

	Module.log.open(Module)
	Module.log.write(Module, {"Generating compile_commands.json..."})
	local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
	vim.api.nvim_buf_add_highlight(Module.log.id, Module.compile_commands.hl_namespace_id, 'UE5CompileCommandsPath', num_lines-1, 11, 32)

	local flags = " "
	local compile_commands = project_config['compile_commands']
	flags_table = compile_commands['flags']
	for _, flag in pairs(flags_table) do
		flags = flags .. flag .. " "
	end
	
	local command_string = "jq '.[0] = .[1] | map(.arguments = [\"clang++" .. flags .. "\" + .file + \" \" + .arguments[1]])' " .. Module.compile_commands.get_project_compile_commands_path(project_name) .. " " .. Module.compile_commands.get_engine_compile_commands_path(options['unreal_engine_path']) .. " > " .. Module.compile_commands.get_output_path()
	
	vim.fn.jobstart(
		command_string,
		{
			on_exit = function(job_id, code, event)
				if event == 'exit' and code == 0 then
					Module.log.write(Module, {"compile_commands.json generated!"})
					local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
					vim.api.nvim_buf_add_highlight(Module.log.id, Module.compile_commands.hl_namespace_id, 'UE5CompileCommandsPath', num_lines-1, 0, 21)
					vim.api.nvim_buf_add_highlight(Module.log.id, Module.compile_commands.hl_namespace_id, 'UE5CompileCommandsSuccess', num_lines-1, 22, -1)
				else
					Module.log.write(Module, {"Failed to generate compile_commands.json..."})
					local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
					vim.api.nvim_buf_add_highlight(Module.log.id, Module.compile_commands.hl_namespace_id, 'UE5CompileCommandsFail', num_lines-1, 0, 18)
					vim.api.nvim_buf_add_highlight(Module.log.id, Module.compile_commands.hl_namespace_id, 'UE5CompileCommandsPath', num_lines-1, 19, 40)
				end
			end
		}
	)
end

return compile_commands
