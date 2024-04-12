local headers = {}

local utils = require("nvim-ue5.utils")

function headers.generate_header_files(config, module_name, platform)
	local options = config.options
	local project_name = config.project['project_name']

	local project_string = '-Project=' .. vim.loop.cwd() .. '/' .. project_name .. '.uproject'
	local target_string = '-Target=' .. module_name .. ' ' .. platform .. ' Development'

	vim.api.nvim_out_write("Generating header files for " .. module_name .. "\n")
	local command_string = utils.get_build_script_path(options) .. ' -Mode=UnrealHeaderTool "' .. target_string .. ' ' .. project_string .. '"'
	utils.async_command_with_output(command_string,
	{
		success='Header files generated!\n',
		fail='Failed to generate header files...\n'
	})
end

return headers
