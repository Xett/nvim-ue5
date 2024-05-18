local headers = {}

function headers.bind(Module)
	vim.api.nvim_create_user_command('UEGenerateHeaders',
		function(opts)
			local module_name = opts['fargs'][1]
			local platform = opts['fargs'][2] or Module.utils.get_current_platform()
			Module.headers.generate_header_files(Module, module_name, platform)
		end,
		{
			nargs='*',
		})
end

function headers.unbind(Module)
	vim.api.nvim_del_user_command('UEGenerateHeaders')
end

function headers.generate_header_files(Module, module_name, platform)
	local config = Module.config

	Module.log.open(Module)

	local options = config.options
	local project_name = config.project['project_name']

	local project_string = '-Project=' .. vim.loop.cwd() .. '/' .. project_name .. '.uproject'
	local target_string = '-Target=' .. module_name .. ' ' .. platform .. ' Development'

	Module.log.write(Module, {"Generating header files for " .. module_name})
	local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
	Module.highlights.highlight_module_name(Module, num_lines, 28, -1)
	
	local command_string = Module.utils.get_build_script_path(options) .. ' -Mode=UnrealHeaderTool "' .. target_string .. ' ' .. project_string .. '"'
	
	vim.fn.jobstart(
		command_string,
		{
			on_exit = function(job_id, code, event)
				if event == 'exit' and code == 0 then
					Module.log.write(Module, {"Header files generated!"})
					local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
					Module.highlights.highlight_success(Module, num_lines)
				else
					Module.log.write(Module, {"Failed to generate header files..."})
					local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
					Module.highlights.highlight_fail(Module, num_lines)
				end
			end,
			on_stdout = function (chan_id, data, name)
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

return headers
