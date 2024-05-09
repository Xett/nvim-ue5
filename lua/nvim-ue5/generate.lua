local generate = {}

local utils = require("nvim-ue5.utils")

function generate.get_arguments_string(project_name)
	return '-projectfiles -project="' .. vim.loop.cwd() .. '/' .. project_name .. '.uproject" -cmakefile -vscode -game -engine'
end

function generate.parse_output(chan_id, data, name)
	local last_key, last_value
	for key, value in pairs(data) do
		if value ~= ' 100%' and value ~= '\t' and value ~='' then
			print('UEGenerateProject:', value)
		end
	end
end

function generate.generate_project_files(Module)
	local options = Module.config.options
	local project_name = Module.config.project['project_name']
	local generate_project_script_path = utils.get_generated_script_path(options)
	if not generate_project_script_path then
		--- Unknown platform, raise an error?
		return
	end

	Module.bot_buf.open(Module)
	Module.bot_buf.write(Module, {"Generating project files"})

	local command_string = generate_project_script_path .. " " .. generate.get_arguments_string(project_name)
	
	vim.fn.jobstart(
		command_string,
		{
			on_exit = function(job_id, code, event)
				if event == 'exit' and code == 0 then
					Module.bot_buf.append(Module, {"Project generated"})
				else
					Module.bot_buf.append(Module, {"Project failed to generate..."})
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

return generate
