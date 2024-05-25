                                          /$$                                           /$$$$$$$
                                         |__/                                          | $$____/
                     /$$$$$$$  /$$    /$$ /$$ /$$$$$$/$$$$          /$$   /$$  /$$$$$$ | $$
                    | $$__ $$$|  $$  /$$/| $$| $$_ $$$_ $$$ /$$$$$$| $$  | $$ /$$__  $$| $$$$$$$
                    | $$  \ $$ \  $$/$$/ | $$| $$ \ $$ \ $$|______/| $$  | $$| $$$$$$$$|_____  $$
                    | $$  | $$  \  $$$/  | $$| $$ | $$ | $$        | $$  | $$| $$_____/ /$$  \ $$
                    | $$  | $$   \  $/   | $$| $$ | $$ | $$        |  $$$$$$/|  $$$$$$$|  $$$$$$/
                    |__/  |__/    \_/    |__/|__/ |__/ |__/         \______/  \_______/ \______/

# Introduction    
Unreal Engine isn't specifically built with neovim in mind, this plugin aims to provide a framework for managing Unreal Engine 5 projects within neovim.

This support can be broken down into the following parts:
    - Project Management
    - LSP Integration
    - Snippet Generation

The following sections go into more detail.

## Project Management
Unreal Engine uses its own program called the Unreal Build Tool (UBT) to manage building its project, and other tasks such as header and project file generation.

This plugin wraps around the UBT to provide the following features:
    - Generating project files
    - Generating project generated header files
    - Building projects
    - Cleaning projects

## LSP Integration
Unreal Engine makes heavy use of macros and uses special syntax in its class names. Some LSP such as tree-sitter have trouble handling this.

[tree-sitter-cpp-ue5](https://github.com/Xett/tree-sitter-cpp-ue5) can be used to handle this, but by default .h/.cpp files are recognised as cpp files and handled by tree-sitter-cpp. This plugin implements commands to set the filetype of .h/.cpp files to cpp_ue5 so that tree-sitter-cpp-ue5 can be properly implemented.

To properly utilise completion services, compile_commands.json needs to be generated, and .clangd must also be generated. For compile_commands.kson to be generated the project must be generated for vscode. To generate this, build_configuration.xml should be like the following:
```xml
<? xml version="1.0" encoding=utf-8" ?>
<Configuration xmlns="https://www.unrealengine.com/BuildConfiguration">
    <ProjectFileGenerator>
        <Format>VisualStudioCode</Format>
    </ProjectFileGenerator>
</Configuration>
```

When the line that GENERATED_BODY() or any macro like that is on changes, errors will be produced due to the line number being used in the generated header file associated with the class. This can be fixed by generating the header files again.

## Snippet Generator
Unreal Engine classes and structs require boilerplat headers which can be generated via the editor, but this plugin can also handle generation.

The following types can be generated:
    - UClass
    - AActor
    - FStruct
    - UInterface/IInterface

# Requirements
## Neovim Plugins
- cmp_nvim_lsp
- nvim-lspconfig
- plenary.nvim

## Programs
- jq

# Setup
This plugin can be installed via various plugin managers.

Packer
```lua
use {
    'Xett/nvim-ue5',
    requires = {
        'neovim/nvim-lspconfig',
        'nvim-lua/plenary.nvim'
    }
}
```

The plugin needs to be initialised in your init.lua as the following:
```lua
local nvim_ue5 = require('nvim_ue5')
nvim_ue5.setup({
    unreal_engine_path = "path/to/unreal/engine/source"
})
```

Inside each project's directory, you need to make a project_config.lua file, where you can define project specific configurations. The plugin has default settings which can be overriden, if you wish to just use the default settings you can set your project_config.lua to the following:
```lua
return {}
```

The default settings are as follows:
```lua
return {
    clean_map = {
        root = {
            mode = "delete_specific",
            whitelist_files = {
                ".uproject$",
                "^project_config.lua$",
            },
            files_to_delete = {
                ".clangd",
                "compile_commands.json",
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
                        ".uplugin",
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
        debug_flags = {},
    },
    compile_commands = {
        flags = {
            "-std=c++20",
            "-ferror-limit=0",
            "-Wall",
            "-Wextra",
            "-Wpedantic",
            "-Wshadow-all",
            "-Wno-unused-parameter",
        },
    }
}
```

# Commands
|Command|Description|Usage|
|------|------|------|
|UEInfo|Shows plugin and project specific information.|```UEInfo```|

## Project Management
|Command|Description|Usage|Defaults|
|------|------|------|------|
|UEClean|Removes files from the project according to the project configuration.|```UEClean```||
|UEGenerateProject|Generates the project files.|```UEGenerateProject```||
|UEBuild|Builds the project using the UBT.|```UEBuild [Target] [Target Type] [Platform]```|Target: ```Development```<br />Target Type: ```Editor```<br />Platform: ```Current Platform```|
|UEGenerateHeaders|This command generates the header files using the UBT.|```UEGenerateHeaders [Module Name] [Platform]```|Platform: ```Current Platform```|

## LSP Integration
|Command|Description|Usage|
|------|------|------|
|UEGenerateClangd|Generates .clangd.|```UEGenerateClangd```|
|UEGenerateCompileCommands|Generates compile_commands.json.|```UEGenerateCompileCommands```|

## Snippets Generator
Snippet generator command arguments after the name don't care about order, this is because if you ommit an argument it will resort to its default value.

|Command|Description|Usage|Defaults|
|------|------|------|------|
|UEClass|Generates a UClass header.|```UEClass [Name] params:[Param1],[Param2] parents:[Parent1],[Parent2]```|params: ```nil```<br />parents: ```UObject```|
|UEActor|Generates an AActor header.|```UEActor [Name] params:[Param1],[Param2] parents:[Parent1],[Parent2]```|params: ```nil```<br />parents: ```AActor```|
|UEStruct|Generates a FStruct header.|```UEStruct [Name] params:[Param1],[Param2] parents:[Parent1],[Parent2]```|params: ```nil```<br />parents: ```nil```|
|UEInterface|Generates a UInterface header, and an IInterface header.|```UEInterface [Name] params:[Param1],[Param2] uparents:[Parent1],[Parent2] iparents:[Parent1],[Parent2]```|params: ```nil```<br />uparents: ```UInterface```<br />iparents: ```nil```|

# Highlight Groups
## nvim-ue5
- UE5Success
- UE5Fail
- UE5Path
- UE5ModuleName
- UE5Seconds
- UE5CleaningModeAll
- UE5CleaningModeSpecific
- UE5Brackets

## tree-sitter-cpp-ue5
- @ue.name.uobject
- @ue.name.aactor
- @ue.name.fstruct
- @ue.name.ttemplate
- @ue.name.iinterface
- @ue.name.eenum
- @ue.item.eenum
- @ue.safety.type
- @ue.text.type
- @ue.specifier.type
- @ue.field.declaration.type
- @ue.generated.type
- @ue.delegate.type
- @ue.parameter.identifier
- @ue.gameplay.tag
- @ue.gameplay.tag.type
- @ue.log.call
- @ue.namespace

# Links
[tree-sitter-cpp-ue5](https://github.com/Xett/tree-sitter-cpp-ue5)
