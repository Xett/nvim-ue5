# nvim-ue5
## Features
### UEInfo
Shows plugin information.
### UEClean
Cleans the project according to the clean_map table in the config.
### UEGenerateProject
Generates the project solution files. Akin to calling GenerateProjectFiles.bat/sh for the project.
### UEGenerateHeaders
Generates the project header files using the UBT/UHT.
Takes 2 arguments, module name and platform.
### UEGenerateClangd
Generates a .clangd file according to the clangd settings in the config.
### UEGenerateCompileCommands
Generates a compile_commands.json file, require jq to be installed as it uses that.
### UEBuild
Runs the UBT on the project.
Requires 3 arguments, target, target type and platform. Defaults to Development, Editor and the current platform.
### UEClass
Generates a UClass header definition (text only) below the current cursor position accounting for tab indentation.
Requres 3 arguments: class name, UCLASS parameters, and parent classes. 
The class name must come first, and does not need the preceding U, while parameters and parents can be omitted or in any order.
UCLASS parameters must be written as args:Param1,Param2 and parent classes must be written as parents:Parent1,Parent2.
If no parents are given, it will default to UObject.
### UEActor
Generates a UClass header like UEClass, but parents will default to AActor.
### UEStruct
Generates a struct header like UEClass, but parents will not have a default.
### UEInterface
Genereates a UInterface and IInterface header. 
Instead of using parents, you must use uparents for the parents of the UInterface class, and iparents for the parents of the IInterface class. 
uparents will default to UInterface.
## Installation
### Packer
``` lua
use {
  'Xett/nvim-ue5',
  requires = {
    'nvim-lua/plenary.nvim'
  }
}
```
### init.lua
``` lua
local ue5 = require('nvim-ue5')
ue5.setup({
  unreal_engine_path = "path/to/unreal_engine_source"
})
```
### project_config.lua
Inside the unreal engine project, project_config.lua needs to be created for the engine to properly detect the directory is an unreal engine project. This is also where per-project settings are definied.
You can just create a blank file with the following:
``` lua
return {}
```

The default project_config.lua is essentially the following:
``` lua
return {
  clean_map = {
    root = {
      mode = "delete_specific",
      whitelist_files = {
        '.uproject$',
        '^project_config.lua$',
      },
      files_to_delete = {
        '.clangd',
        'CMakeLists.txt',
        'compile_commands.json',
      },
    Binaries = {
      mode = 'delete_all',
      whitelist_files = {},
      files_to_delete = {},
    },
    Build = {
      mode = 'delete_all',
      whitelist_files = {},
      files_to_delete = {},
    },
    DerivedDataCache = {
      mode = 'delete_all',
      whitelist_files = {},
      files_to_delete = {},
    },
    Intermediate = {
      mode = 'delete_all',
      whitelist_files = {},
      files_to_delete = {},
    },
    Saved = {
      mode = 'delete_all',
      whitelist_files = {},
      files_to_delete = {},
    },
    Plugins = {
      default = {
        root = {
          mode = 'delete_specific',
          whitelist_files = {
            '.uproject$',
          },
          files_to_delete = {},
        },
        Binaries = {
          mode = 'delete_all',
          whitelist_files = {},
          files_to_delete = {},
        },
        Intermediate = {
          mode = 'delete_all',
          whitelist_files = {},
          files_to_delete = {},
        },
      },
    },
  },
  clangd = {
    debug_flags = {
      '__INTELLISENSE__=1',
    },
  },
  compile_commands = {
    flags = {
      '-std=c++20',
      '-ferror-limit=0',
      '-Wall',
      '-Wextra',
      '-Wpedantic',
      '-Wshadow-all',
      '-Wno-unused-parameter'
    },
  },
}
```
