local config = {}

local default_options = {
	unreal_engine_path = "",
}

config.options = {}

local default_project_config = {
	clean_map = {
		root = {
			mode = "delete_specific",
			whitelist_files = {
				'.uproject$', --- Just in case somebody changes mode to delete_all without thinking
				'^project_config.lua$',
			},
			files_to_delete = {
				'.clangd',
				'CMakeLists.txt',
				'compile_commands.json',
				--- Other local build files need to be listed here for deletion too
			},
		},
		Binaries = {
			mode = "delete_all",
			whitelist_files = {},
			files_to_delete = {},
		},
		Build = {
			mode = "delete_all",
			whitelist_files = {},
			files_to_delete = {},
		},
		DerivedDataCache = {
			mode = "delete_all",
			whitelist_files = {},
			files_to_delete = {},
		},
		Intermediate = {
			mode = "delete_all",
			whitelist_files = {},
			files_to_delete = {},
		},
		Saved = {
			mode = "delete_all",
			whitelist_files = {},
			files_to_delete = {},
		},
		Plugins = {
			default = {
				root = {
					mode = "delete_specific",
					whitelist_files = {
						'.uproject$',
					},
					files_to_delete = {},
				},
				Binaries = {
					mode = "delete_all",
					whitelist_files = {},
					files_to_delete = {},
				},
				Intermediate = {
					mode = "delete_all",
					whitelist_files = {},
					files_to_delete = {},
				},
			},
		},
	},
	clangd = {
		debug_flags = {}
	},
	compile_commands = {
		flags = {
			'-std=c++20',
			'-ferror-limit=0',
			'-Wall',
			'-Wextra',
			'-Wpedantic',
			'-Wshadow-all',
			'-Wno-unused-parameter',
		},
	},
}

local default_project = {
	project_name = '',
	module_names = {},
	build_targets = {},
	config = default_project_config,
}

config.project = default_project

function config.reset_project()
	config.project = default_project
end

function config.setup_project(project_config)
	config.project['config'] = vim.tbl_deep_extend("force", {}, default_project_config, project_config or {})
end

function config.setup(options)
	config.options = vim.tbl_deep_extend("force", {}, default_options, options or {})
end

return config
