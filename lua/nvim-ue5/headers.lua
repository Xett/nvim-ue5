--- Initialise Module
local headers = {}

--- Bind Commands
function headers.bind(Module)
	vim.api.nvim_create_user_command('UEGenerateHeaders',
		function(opts)
			local module_name = opts['fargs'][1]
			if not Module.utils.module_name_is_valid(Module, module_name) then
				vim.api.nvim_err_writeln("Invalid module name")
				return
			end

			local platform = opts['fargs'][2] or Module.utils.get_current_platform()
			if not Module.utils.platform_is_valid(Module, platform) then
				vim.api.nvim_err_writeln("Invalid platform")
				return
			end

			local target = opts['fargs'][3] or 'Development'
			if not Module.utils.target_is_valid(Module, target) then
				vim.api.nvim_err_writeln("Invalid target")
				return
			end

			Module.headers.generate_header_files(Module, module_name, platform, target)
		end,
		{
			nargs='*',
			desc="Generate project headers, requires a specified Module Name, takes the platform (defaults to the current platform) and the target (defaults to Development)",	
		})
end

--- Unbind Commands
function headers.unbind(Module)
	vim.api.nvim_del_user_command('UEGenerateHeaders')
end

--- Use the Unreal Build Tool to generate the .generated.h header files, and log the output of the UBT
function headers.generate_header_files(Module, module_name, platform, target)
	Module.log.open(Module)

	local options = Module.config.options
	local project_name = Module.config.project['project_name']

	local project_string = '-Project=' .. vim.loop.cwd() .. '/' .. project_name .. '.uproject'
	local target_string = '-Target=' .. module_name .. ' ' .. platform .. ' ' .. target

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

--- Return Module
return headers
