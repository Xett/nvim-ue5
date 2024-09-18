--- Initialise Module
local commands = {}

--- Variables
commands.is_bound = false

--- Separates key:value strings into key and value
function commands.parse_named_command_argument(argument_string)
	local key, value = string.match(argument_string, '([^:]+):(.+)')
	if key and value then
		return key, value
	end
end

function commands.init(Module)

	--- Create the augroup
	Module.commands.augroup = vim.api.nvim_create_augroup("nvim-ue5", {})

	--- Called when opening neovim or when changing the directory
	Module.commands.enter_command_id = vim.api.nvim_create_autocmd({"VimEnter", "DirChanged"}, {
		group = Module.commands.augroup,
		pattern = "*",
		callback = function(ev)
			--- Call the scan function from the init file
			Module.scan()

			--- Check if clangd is already set up in lsp config
			local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
			local lsp_config = require('lspconfig')

			--- Save the old clangd config, before we change it
			Module.old_clangd_config = lsp_config['clangd']

			--- Setup clangd
			lsp_config['clangd'].setup{
				cmd = {
					"clangd",
					"--background-index",
					"--suggest-missing-includes",
					"--compile-commands-dir=" .. vim.loop.cwd(),
				},
				filetypes = {
					"c",
					"cpp",
					"h",
					"hpp",
				},
				capabilities = lsp_capabilities,
			}

			--- Restart the Lsp
			vim.cmd([[ LspRestart ]])
		end
	})	
end

--- Bind all the commands
function commands.bind(Module)
	--- Change cpp filetype to cpp_ue5 (for linting)
	Module.commands.cpp_open_command_id = vim.api.nvim_create_autocmd({"BufReadPost"}, {
		group = commands.augroup,
		pattern = "*.cpp",
		callback = function(ev)
			vim.cmd("set filetype=cpp_ue5")	
		end
	})

	--- Change h filetype to cpp_ue5 (for linting)
	Module.commands.h_open_command_id = vim.api.nvim_create_autocmd({"BufReadPost"}, {
		group = commands.augroup,
		pattern = "*.h",
		callback = function(ev)
			vim.cmd("set filetype=cpp_ue5")
		end
	})

	--- Change init filetype to ini_ue5 (for linting)
	Module.commands.ini_open_command_id = vim.api.nvim_create_autocmd({"BufReadPost"}, {
		group = commands.augroup,
		pattern = "*.ini",
		callback = function(ev)
			vim.cmd("set filetype=ini_ue5")
		end
	})
	
	--- Bind the module commands, each module has their own command bind functions
	if not commands.is_bound then
		for _, mod in ipairs(Module.command_modules) do
			mod.bind(Module)
		end		

		commands.is_bound = true
	end
end

--- Unbind all the commands
function commands.unbind(Module)
	--- Unbind all the filetype commands
	vim.api.nvim_del_autocmd(Module.commands.cpp_open_command_id)
	vim.api.nvim_del_autocmd(Module.commands.h_open_command_id)
	vim.api.nvim_del_autocmd(Module.commands.ini_open_command_id)

	--- Unbind the module commands
	if commands.is_bound then
		for _, mod in ipairs(Module.command_modules) do
			mod.unbind(Module)
		end

		commands.is_bound = false
	end
end

--- Return Module
return commands
