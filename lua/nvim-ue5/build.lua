local build = {}

local utils = require("nvim-ue5.utils")

function build.build(config, target, target_type, platform)

	local uproject_path = vim.loop.cwd() .. '/' .. config.project['project_name'] .. '.uproject'

	local command_string = utils.get_build_script_path(config.options) .. ' ' .. target .. ' ' .. platform .. ' -Project="' .. uproject_path .. '" -TargetType=' .. target_type .. ' -Progress'
	utils.async_command_with_output(command_string,
	{
		success='Build successful!\n',
		fail='Build failed...\n',
	})

end

return build
