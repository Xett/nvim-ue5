local compile_commands = {}
local utils = require("nvim-ue5.utils")
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
	local project_name = Module.config.project['config_name']

	Module.utils.open_bottom_buffer(Module)
	Module.utils.write_to_bottom_buffer(Module, {"Generating compile_commands.json..."})

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
					Module.utils.append_to_bottom_buffer(Module, {"compile_commands.json generated!"})
				else
					Module.utils.append_to_bottom_buffer(Module, {"Failed to generate compile_commands.json..."})
				end
			end
		}
	)
end

return compile_commands
