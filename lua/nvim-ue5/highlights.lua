--- Initialise Module
local highlights = {}

--- VARIABLES
highlights.namespace_id = nil

--- Create the namespace id
function highlights.create_ns_id(Module)
	Module.highlights.namespace_id = vim.api.nvim_create_namespace('nvim_ue5')
end

--- Create the highlight groups
function highlights.create_groups(Module)
	vim.cmd('highlight UE5Success ctermfg=Green')
	vim.cmd('highlight UE5Fail ctermfg=Red')
	vim.cmd('highlight UE5Path ctermfg=18')
	vim.cmd('highlight UE5ModuleName ctermfg=Yellow')
	vim.cmd('highlight UE5Seconds ctermfg=Blue')
	vim.cmd('highlight UE5CleaningModeAll ctermfg=Red')
	vim.cmd('highlight UE5CleaningModeSpecific ctermfg=Red')
	vim.cmd('highlight UE5Brackets ctermfg=Yellow')
end

--- Highlight a line (or lines) in the log window
function highlights.highlight_line(Module, highlight_group, num_lines)
	vim.api.nvim_buf_add_highlight(Module.log.id, Module.highlights.namespace_id, highlight_group, num_lines-1, 0, -1)
end

--- Highlight using the UE5Success highlight group for a line (or lines) in the log window 
function highlights.highlight_success(Module, num_lines)
	vim.api.nvim_buf_add_highlight(Module.log.id, Module.highlights.namespace_id, 'UE5Success', num_lines-1, 0, -1)
end

--- Highlight using the UE5Fail highlight group for a line (or lines) in the log window
function highlights.highlight_fail(Module, num_lines)
	vim.api.nvim_buf_add_highlight(Module.log.id, Module.highlights.namespace_id, 'UE5Fail', num_lines-1, 0, -1)
end

--- Highlight using the UE5ModuleName highlight group for a line (or lines) and pass in the start and end indexes
function highlights.highlight_module_name(Module, num_lines, start_idx, end_idx)
	vim.api.nvim_buf_add_highlight(Module.log.id, Module.highlights.namespace_id, 'UE5ModuleName', num_lines-1, start_idx, end_idx)
end

--- Parse a line (or lines) in the log window, and highlight any paths using the UE5Path highlight group
function highlights.highlight_paths(Module, line, num_lines)
	local platform = Module.utils.get_current_platform()

	if platform == "Linux" then
		local path_pattern = vim.regex('\\([A-Za-z0-9_-~]*\\/[A-Za-z0-9_-]*\\)\\+\\.*\\([A-Za-z0-9_-]\\+\\)*')
		local path_start_pos = 0
		local matches = {}
		
		while path_start_pos <= #line do
			local start_idx, end_idx = path_pattern:match_str(line:sub(path_start_pos+1))
			if type(start_idx) == 'number' then
				start_idx = start_idx + path_start_pos
				end_idx = end_idx + path_start_pos
				table.insert(matches, {start_idx, end_idx})
				path_start_pos = end_idx
			else
				break
			end
		end
		for i, value in ipairs(matches) do
			vim.api.nvim_buf_add_highlight(Module.log.id, Module.highlights.namespace_id, 'UE5Path', num_lines-1, value[1], value[2])
		end
	end
end

--- Parse a line (or lines) in the log window, and highlight any "seconds" using the UE5Seconds highlight group
function highlights.highlight_seconds(Module, string, num_lines)
	local seconds_pattern = vim.regex('\\([0-9]\\)\\+\\.\\([0-9]\\)\\+ seconds')
	local start_idx, end_idx = seconds_pattern:match_str(string)
	if type(start_idx) == 'number' then
		vim.api.nvim_buf_add_highlight(Module.log.id, Module.highlights.namespace_id, 'UE5Seconds', num_lines-1, start_idx, end_idx)
	end
end


--- Parse a number of lines in the log window, and highlight all the module names
function highlights.highlight_module_names(Module, string, num_lines)
	local target_module_name_pattern = vim.regex('\\(Running command : dotnet \\).*\\(-Target=\\)')
	local start_idx, end_idx = target_module_name_pattern:match_str(string)
	if type(start_idx) == 'number' then
		local target_module_name_pattern = vim.regex('[A-Za-z]*')
		local new_start_idx, new_end_idx = target_module_name_pattern:match_str(string:sub(end_idx+1))
		if type(new_start_idx) == 'number' then
			vim.api.nvim_buf_add_highlight(Module.log.id, Module.highlights.namespace_id, 'UE5ModuleName', num_lines-1, end_idx, new_end_idx+end_idx)
		end
	end

	local compiling_pattern = vim.regex('\\(Compiling \\)')
	local start_idx, end_idx = compiling_pattern:match_str(string)
	if type(start_idx) == 'number' then
		local module_name_pattern = vim.regex('[A-Za-z]*')
		local new_start_idx, new_end_idx = module_name_pattern:match_str(string:sub(end_idx+1))
		if type(new_start_idx) == 'number' then
			vim.api.nvim_buf_add_highlight(Module.log.id, Module.highlights.namespace_id, 'UE5ModuleName', num_lines-1, end_idx, new_end_idx+end_idx)
		end
	end	
end

--- Return Module
return highlights
