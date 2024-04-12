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

function generate.generate_project_files(options, project_name)
	local generate_project_script_path = utils.get_generated_script_path(options)
	if not generate_project_script_path then
		--- Unknown platform, raise an error?
		return
	end

	vim.api.nvim_out_write("Generating project...\n")
	local command_string = generate_project_script_path .. " " .. generate.get_arguments_string(project_name)
	vim.fn.jobstart(command_string,
		{
			on_exit = utils.jobstart_on_exit_out_write({
				success='Project generated!\n',
				fail='Project failed to generate...\n',
			}),
			on_stdout = generate.parse_output
		})
end

return generate
