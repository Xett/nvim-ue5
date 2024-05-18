local build = {}

function build.bind(Module)
	vim.api.nvim_create_user_command('UEBuild',
		function(opts)
			local target = opts['fargs'][1] or "Development"
			local target_type = opts['fargs'][2] or "Editor"
			local platform = opts['fargs'][3] or Module.utils.get_current_platform()
			Module.build.build(Module, target, target_type, platform)
		end,
		{
			nargs='*',
		})
end

function build.unbind(Module)
	vim.api.nvim_del_user_command('UEBuild')
end

function build.build(Module, target, target_type, platform)
	local config = Module.config
	Module.log.open(Module)

	local uproject_path = vim.loop.cwd() .. '/' .. config.project['project_name'] .. '.uproject'


	Module.log.write(Module, {"Building " .. config.project['project_name'] .. ' ' .. target .. ' ' .. target_type .. ' ' .. platform})
	local command_string = Module.utils.get_build_script_path(config.options) .. ' ' .. target .. ' ' .. platform .. ' -Project="' .. uproject_path .. '" -TargetType=' .. target_type .. ' -Progress'
	
	vim.fn.jobstart(
		command_string,
		{
			on_exit = function(job_id, code, event)
				if event == 'exit' and code == 0 then
					Module.log.write(Module, {"Build successful!"})
					local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
					Module.highlights.highlight_success(Module, num_lines)
				else
					Module.log.write(Module, {"Build failed..."})
					local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
					Module.highlights.highlight_fail(Module, num_lines)
				end
			end,
			on_stdout = function(chan_id, data, name)
				for key, value in pairs(data) do
					Module.log.write(Module, {value})
					local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
					Module.highlights.highlight_paths(Module, value, num_lines)
					Module.highlights.highlight_seconds(Module, value, num_lines)
					Module.highlights.highlight_module_names(Module, value, num_lines)
				end
			end
		}
	)
end

return build
