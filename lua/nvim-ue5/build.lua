local build = {}

local utils = require("nvim-ue5.utils")

function build.build(Module, target, target_type, platform)
	local config = Module.config
	Module.bot_buf.open(Module)

	local uproject_path = vim.loop.cwd() .. '/' .. config.project['project_name'] .. '.uproject'


	Module.bot_buf.write(Module, {"Building " .. config.project['project_name'] .. ' ' .. target .. ' ' .. target_type .. ' ' .. platform})
	local command_string = utils.get_build_script_path(config.options) .. ' ' .. target .. ' ' .. platform .. ' -Project="' .. uproject_path .. '" -TargetType=' .. target_type .. ' -Progress'
	
	vim.fn.jobstart(
		command_string,
		{
			on_exit = function(job_id, code, event)
				if event == 'exit' and code == 0 then
					Module.bot_buf.append(Module, {"Build successful!"})
				else
					Module.bot_buf.append(Module, {"Build failed..."})
				end
			end,
			on_stdout = function(chan_id, data, name)
				for key, value in pairs(data) do
					Module.bot_buf.append(Module, {value})
				end
			end
		}
	)
end

return build
