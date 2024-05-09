local build = {}

local utils = require("nvim-ue5.utils")

function build.build(Module, target, target_type, platform)
	local config = Module.config
	Module.utils.open_bottom_buffer(Module)

	local uproject_path = vim.loop.cwd() .. '/' .. config.project['project_name'] .. '.uproject'


	Module.utils.write_to_bottom_buffer(Module, {"Building " .. config.project['project_name'] .. ' ' .. target .. ' ' .. target_type .. ' ' .. platform})
	local command_string = utils.get_build_script_path(config.options) .. ' ' .. target .. ' ' .. platform .. ' -Project="' .. uproject_path .. '" -TargetType=' .. target_type .. ' -Progress'
	
	vim.fn.jobstart(
		command_string,
		{
			on_exit = function(job_id, code, event)
				if event == 'exit' and code == 0 then
					Module.utils.append_to_bottom_buffer(Module, {"Build successful!"})
				else
					Module.utils.append_to_bottom_buffer(Module, {"Build failed..."})
				end
			end,
			on_stdout = function(chan_id, data, name)
				for key, value in pairs(data) do
					Module.utils.append_to_bottom_buffer(Module, {value})
				end
			end
		}
	)
end

return build
