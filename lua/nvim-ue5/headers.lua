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

	Module.bot_buf.open(Module)

	local options = config.options
	local project_name = config.project['project_name']

	local project_string = '-Project=' .. vim.loop.cwd() .. '/' .. project_name .. '.uproject'
	local target_string = '-Target=' .. module_name .. ' ' .. platform .. ' Development'

	Module.bot_buf.write(Module, {"Generating header files for " .. module_name})
	
	local command_string = Module.utils.get_build_script_path(options) .. ' -Mode=UnrealHeaderTool "' .. target_string .. ' ' .. project_string .. '"'
	
	vim.fn.jobstart(
		command_string,
		{
			on_exit = function(job_id, code, event)
				if event == 'exit' and code == 0 then
					Module.bot_buf.write(Module, {"Header files generated!"})
				else
					Module.bot_buf.write(Module, {"Failed to generate header files..."})
				end
			end,
			on_stdout = function (chan_id, data, name)
				for key, value in pairs(data) do
					Module.bot_buf.write(Module, {value})
				end
			end
		}
	)
end

return headers
