--- Initialise Module
local generate = {}

--- Bind Commands
function generate.bind(Module)
	vim.api.nvim_create_user_command('UEGenerateProject',
		function(opts)
			Module.generate.generate_project_files(Module)
		end,
		{
			desc="Generate the project files",	
		})
end

--- Unbind Commands
function generate.unbind(Module)
	vim.api.nvim_del_user_command('UEGenerateProject')
end

function generate.get_arguments_string(project_name)
	return '-projectfiles -project="' .. vim.loop.cwd() .. '/' .. project_name .. '.uproject" -game -engine'
end

function generate.generate_project_files(Module)
	local options = Module.config.options
	local project_name = Module.config.project['project_name']
	local generate_project_script_path = Module.utils.get_generated_script_path(options)
	if not generate_project_script_path then
		--- Unknown platform, raise an error?
		return
	end

	Module.log.open(Module)
	Module.log.write(Module, {"Generating project files"})

	local command_string = generate_project_script_path .. " " .. generate.get_arguments_string(project_name)
	
	vim.fn.jobstart(
		command_string,
		{
			on_exit = function(job_id, code, event)
				if event == 'exit' and code == 0 then
					Module.log.write(Module, {"Project generated"})
					local num_lines = vim.api.nvim_buf_line_count(Module.log.id)
					Module.highlights.highlight_success(Module, num_lines)
				else
					Module.log.write(Module, {"Project failed to generate..."})
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

--- Return Module
return generate
