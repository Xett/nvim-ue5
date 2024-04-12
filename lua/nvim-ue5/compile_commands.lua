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

function compile_commands.build_compile_commands(options, project_config, project_name)
	vim.api.nvim_out_write("Generating compile_commands.json...\n")
	local flags = " "
	local compile_commands = project_config['compile_commands']
	flags_table = compile_commands['flags']
	for _, flag in pairs(flags_table) do
		flags = flags .. flag .. " "
	end
	local command_string = "jq '.[0] = .[1] | map(.arguments = [\"clang++" .. flags .. "\" + .file + \" \" + .arguments[1]])' " .. compile_commands.get_project_compile_commands_path(project_name) .. " " .. compile_commands.get_engine_compile_commands_path(options['unreal_engine_path']) .. " > " .. compile_commands.get_output_path()
	utils.async_command_with_output(command_string,
	{
		success='compile_commands.json generated!\n',
		fail='Failed to generate compile_commands.json...\n',
	})
end

return compile_commands
