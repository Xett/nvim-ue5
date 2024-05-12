local compile_commands = {}

function compile_commands.bind(Module)
	vim.api.nvim_create_user_command('UEGenerateCompileCommands',
		function(opts)
			Module.compile_commands.build_compile_commands(Module)
		end,
		{})
end

function compile_commands.unbind(Module)
	vim.api.nvim_del_user_command('UEGenerateCompileCommands')
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
	local options = Module.config.options
	local project_config = Module.config.project['config']
	local project_name = Module.config.project['project_name']

	Module.bot_buf.open(Module)
	Module.bot_buf.write(Module, {"Generating compile_commands.json..."})

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
					Module.bot_buf.write(Module, {"compile_commands.json generated!"})
				else
					Module.bot_buf.write(Module, {"Failed to generate compile_commands.json..."})
				end
			end
		}
	)
end

return compile_commands
