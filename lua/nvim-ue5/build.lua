--- Initialise Module
local build = {}

--- Bind Commands
function build.bind(Module)
	vim.api.nvim_create_user_command('UEBuild',
		function(opts)
			--- First argument is the Build Target, defaults to Development
			local target = opts['fargs'][1] or "Development"
			--- Throw an error if the Build Target is not valid
			if not Module.utils.target_is_valid(Module, target) then
				vim.api.nvim_err_writeln("Invalid build target")
				return
			end

			--- Second argument is the Target Type, defaults to Editor
			local target_type = opts['fargs'][2] or "Editor"
			--- Throw an error if the Build Target is not valid
			if not Module.utils.target_type_is_valid(Module, target_type) then
				vim.api.nvim_err_writeln("Invalid build target type")
				return
			end

			--- Third argument is Platform, defaults to the current platform
			local platform = opts['fargs'][3] or Module.utils.get_current_platform()
			--- Throw an error if the Platform is not valid
			if not Module.utils.platform_is_valid(Module, platform) then
				vim.api.nvim_err_writeln("Invalid platform")
				return
			end

			Module.build.build(Module, target, target_type, platform)
		end,
		{
			nargs='*',
			desc="Build the project, takes the target (defaults to Development), the target type (defaults to Editor) and the platform (defaults to the current platform)",
		})
end

--- Unbind Commands
function build.unbind(Module)
	vim.api.nvim_del_user_command('UEBuild')
end

--- Build
function build.build(Module, target, target_type, platform)
	--- Variables
	local config = Module.config

	--- Ensure that the log window is open
	Module.log.open(Module)

	--- We get the name of the project from the .uproject file, so this SHOULD be valid
	local uproject_path = vim.loop.cwd() .. '/' .. config.project['project_name'] .. '.uproject'


	--- Log out the arguments and everything
	Module.log.write(Module, {"Building " .. config.project['project_name'] .. ' ' .. target .. ' ' .. target_type .. ' ' .. platform})
	
	--- The actual command we will be executing
	local command_string = Module.utils.get_build_script_path(config.options) .. ' ' .. target .. ' ' .. platform .. ' -Project="' .. uproject_path .. '" -TargetType=' .. target_type .. ' -Progress'

	--- Call in async, so we can log the output and not hold up neovim
	vim.fn.jobstart(
		command_string,
		{
			--- Log if the command failed or succeeded
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
			--- Log the output while running
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

--- Return Module
return build
