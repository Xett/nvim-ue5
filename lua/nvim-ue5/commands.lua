local commands = {}

commands.is_bound = false

function commands.parse_named_command_argument(argument_string)
	local key, value = string.match(argument_string, '([^:]+):(.+)')
	if key and value then
		return key, value
	end
end

function commands.init(Module)

	Module.commands.augroup = vim.api.nvim_create_augroup("nvim-ue5", {})

	Module.commands.enter_command_id = vim.api.nvim_create_autocmd({"VimEnter", "DirChanged"}, {
		group = Module.commands.augroup,
		pattern = "*",
		callback = function(ev)
			Module.scan()

			--- Check if clangd is already set up in lsp config
			local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
			local lsp_config = require('lspconfig')

			Module.old_clangd_config = lsp_config['clangd']
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
			vim.cmd([[ LspRestart ]])
		end
	})

	Module.commands.cpp_open_command_id = vim.api.nvim_create_autocmd({"BufReadPost"}, {
		group = commands.augroup,
		pattern = "*.cpp",
		callback = function(ev)
			vim.cmd("set filetype=cpp_ue5")	
		end
	})

	Module.commands.h_open_command_id = vim.api.nvim_create_autocmd({"BufReadPost"}, {
		group = commands.augroup,
		pattern = "*.h",
		callback = function(ev)
			vim.cmd("set filetype=cpp_ue5")
		end
	})
end

function commands.bind(Module)
	if not commands.is_bound then
		for _, mod in ipairs(Module.command_modules) do
			mod.bind(Module)
		end		

		commands.is_bound = true
	end
end

function commands.unbind(Module)
	if commands.is_bound then
		for _, mod in ipairs(Module.command_modules) do
			mod.unbind(Module)
		end

		commands.is_bound = false
	end
end

return commands
