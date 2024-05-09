local commands = {}

local utils = require('nvim-ue5.utils')

commands.is_bound = false

function commands.parse_named_command_argument(argument_string)
	local key, value = string.match(argument_string, '([^:]+):(.+)')
	if key and value then
		return key, value
	end
end

function commands.init(Module)

	commands.augroup = vim.api.nvim_create_augroup("nvim-ue5", {})

	commands.enter_command_id = vim.api.nvim_create_autocmd({"VimEnter", "DirChanged"}, {
		group = commands.augroup,
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

	commands.cpp_open_command_id = vim.api.nvim_create_autocmd({"BufReadPost"}, {
		group = commands.augroup,
		pattern = "*.cpp",
		callback = function(ev)
			vim.cmd("set filetype=cpp_ue5")	
		end
	})

	commands.h_open_command_id = vim.api.nvim_create_autocmd({"BufReadPost"}, {
		group = commands.augroup,
		pattern = "*.h",
		callback = function(ev)
			vim.cmd("set filetype=cpp_ue5")
		end
	})
end

function commands.bind(Module)
	if not commands.is_bound then

		vim.api.nvim_create_user_command('UEGenerateProject',
			function(opts)
				Module.generate.generate_project_files(Module)
			end,
			{})

		vim.api.nvim_create_user_command('UEGenerateCompileCommands',
			function(opts)
				Module.compile_commands.build_compile_commands(Module)
			end,
			{})

		vim.api.nvim_create_user_command('UEGenerateHeaders',
			function(opts)
				local module_name = opts['fargs'][1]
				local platform = opts['fargs'][2] or Module.utils.get_current_platform()
				Module.headers.generate_header_files(Module, module_name, platform)
			end,
			{
				nargs='*',
			})

		vim.api.nvim_create_user_command('UEClean',
			function(opts)
				Module.clean.clean(Module)
			end,
			{})

		vim.api.nvim_create_user_command('UEGenerateClangd',
			function(opts)
				Module.clangd.create_clangd_file(Module)
			end,
			{})

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

		vim.api.nvim_create_user_command('UEInfo',
			function(opts)
				Module.info.toggle_window(Module)
			end,
			{})

		vim.api.nvim_create_user_command('UEClass',
			function(opts)
				local class_name = opts['fargs'][1]	--- First argument is ALWAYS the class name (without the prefix)

				local uclass_arguments_string = ''
				local parent_classes_string = ''

				local arg2_type, arg2 = commands.parse_named_command_argument(opts['fargs'][2])
				if arg2_type == 'args' then
					uclass_arguments_string = arg2
				elseif arg2_type == 'parents' then
					parent_classes_string = arg2 or 'UObject'
				end

				local arg3_type, arg3 = commands.parse_named_command_argument(opts['fargs'][3])
				if arg3_type == 'args' then
					uclass_arguments_string = arg3
				elseif arg3_type == 'parents' then
					parent_classes_string = arg3 or 'UObject'
				end

				local uclass_arguments = Module.snippets.parse_macro_arguments_string(uclass_arguments_string)
				local parent_classes = utils.parse_comma_seperated(parent_classes_string)

				Module.snippets.generate_class(class_name, uclass_arguments, parent_classes)
			end,
			{
				nargs='*',
			})

		vim.api.nvim_create_user_command('UEActor',
			function(opts)
				local actor_name = opts['fargs'][1]

				local uclass_arguments_string = ''
				local parent_classes_string = ''

				local arg2_type, arg2 = commands.parse_named_command_argument(opts['fargs'][2])
				if arg2_type == 'args' then
					uclass_arguments_string = arg2
				elseif arg2_type == 'parents' then
					parent_classes_string = arg2 or 'AActor'
				end

				local arg3_type, arg3 = commnads.parse_named_command_argument(opts['fargs'][3])
				if arg3_type == 'args' then
					uclass_arguments_string = arg3
				elseif arg3_type == 'parents' then
					parent_classes_string = arg3 or 'AActor'
				end

				local uclass_arguments = Module.snippets.parse_macro_arguments_string(uclass_arguments_string)
				local parent_classes = utils.parse_comma_seperated(parent_classes_string)

				Module.snippets.generate_actor(actor_name, uclass_arguments, parent_classes)
			end,
			{
				nargs='*',
			})

		vim.api.nvim_create_user_command('UEStruct',
			function(opts)
				local struct_name = opts['fargs'][1]

				local ustruct_arguments_string = ''
				local parent_structs_string = ''

				local arg2_type, arg2 = commands.parse_named_command_argument(opts['fargs'][2])
				if arg2_type == 'args' then
					ustruct_arguments_string = arg2
				elseif arg2_type == 'parents' then
					parent_structs_string = arg2
				end

				local arg3_type, arg3 = commands.parse_named_command_argument(opts['fargs'][3])
				if arg3_type == 'args' then
					ustruct_arguments_string = arg3
				elseif arg3_type == 'parents' then
					parent_structs_string = arg3
				end

				local ustruct_arguments = Module.snippets.parse_macro_arguments_string(ustruct_arguments_string)
				local parent_structs = Module.snippets.parse_parent_classes(parent_struct_string)

				Module.snippets.generate_struct(struct_name, ustruct_arguments, parent_structs)
			end,
			{
				nargs='*',
			})

		vim.api.nvim_create_user_command('UEInterface',
			function(opts)
				local interface_name = opts['fargs'][1]

				local uinterface_arguments = ''
				local uinterface_parents = ''
				local iinterface_parents = ''

				local arg2_type, arg2 = commands.parse_named_command_argument(opts['fargs'][2])
				if arg2_type == 'args' then
					uinterface_arguments = arg2
				elseif arg2_type == 'uparents' then
					uinterface_parents = arg2 or 'UInterface'
				elseif arg2_type == 'iparents' then
					iinterface_parents = arg2
				end

				local arg3_type, arg3 = commands.parse_named_command_argument(opts['fargs'][3])
				if arg3_type == 'args' then
					uinterface_arguments = arg3
				elseif arg3_type == 'uparents' then
					uinterface_parents = arg3 or 'UInterface'
				elseif arg3_type == 'iparents' then
					iinterface_parents = arg3
				end

				local arg4_type, arg4 = commands.parse_named_command_argument(opts['fargs'][4])
				if arg4_type == 'args' then
					uinterface_arguments = arg4
				elseif arg4_type == 'uparents' then
					uinterface_parents = arg4 or 'UInterface'
				elseif arg4_type == 'iparents' then
					iinterface_parents = arg4
				end

				Module.snippets.generate_interface(interface_name, uinterface_arguments, uinterface_parents, iinterface_parents)
			end,
			{
				nargs='*',
			})

		commands.is_bound = true
	end
end

function commands.unbind(Module)
	if commands.is_bound then
		vim.api.nvim_del_user_command('UEGenerateProject')

		vim.api.nvim_del_user_command('UEGenerateCompileCommands')

		vim.api.nvim_del_user_command('UEGenerateHeaders')

		vim.api.nvim_del_user_command('UEClean')

		vim.api.nvim_del_user_command('UEInfo')

		vim.api.nvim_del_user_command('UEClass')

		vim.api.nvim_del_user_command('UEStruct')

		vim.api.nvim_del_user_command('UEInterface')

		vim.api.nvim_del_user_command('UEActor')

		commands.is_bound = false
	end
end

return commands
