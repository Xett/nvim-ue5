--- INCLUDES
local plenary_window = require('plenary.window')
local plenary_window_float = require('plenary.window.float')

--- Initialise Module
local ui = {}

--- Variables
ui.window = {
	win_id = nil
}

ui.default_cursor_line = nil
ui.window_height = nil
ui.window_width = nil

ui.current_state = nil

ui.cursor_update_question = false

ui.preview_table = {
	name = 'Preview',
	params = "",
	parents = "",
}

ui.old_cursor_pos = nil
ui.selected_buffer = nil

--- Bind Commands
function ui.bind(Module)
	vim.api.nvim_create_user_command('UESnip',
		function(opts)
			Module.snippets.ui.toggle_window(Module)
end,
		{
			desc="Snippet generation wizard",
		}

	)
end

--- Unbind Commands
function ui.unbind(Module)
	vim.api.nvim_del_user_command('UESnip')
end

function ui.create_window(Module)
	local width_percentage = 0.6
	local height_percentage = 0.4
	ui.window_width = math.ceil(vim.o.columns * width_percentage)
	ui.window_height = math.ceil(vim.o.lines * height_percentage)
	ui.default_cursor_line = ui.window_height
	ui.question_text_line = ui.window_height-2
	ui.window = plenary_window_float.percentage_range_window(0.6, 0.4, {
		border = 'rounded',
	})	
end

function ui.draw_initial_window(Module)
	--- TITLE
	local title_text = "Unreal Engine Snippet Generator"
	local title = {
		string.rep(" ", math.floor((ui.window_width - #title_text) /2)) .. title_text
	}
	vim.api.nvim_buf_set_lines(ui.window.bufnr, 0, -1, true, title)
	vim.api.nvim_buf_add_highlight(ui.window.bufnr, -1, "Title", 0, 0, ui.window_width)

	--- Border under the title
	ui.border_text_1 = {
		string.rep("=", ui.window_width-1)
	}
	vim.api.nvim_buf_set_lines(ui.window.bufnr, 1, -1, true, ui.border_text_1)

	ui.border_text_2 = {
		string.rep("-", ui.window_width-1)
	}

	local spacing = {}
	for i = 2, ui.window_height-2 do
		table.insert(spacing, "")
	end
	vim.api.nvim_buf_set_lines(ui.window.bufnr, 2, -1, true, spacing)

	vim.api.nvim_buf_set_lines(ui.window.bufnr, -4, -3, false, ui.border_text_2)
	vim.api.nvim_buf_set_lines(ui.window.bufnr, -2, -1, false, ui.border_text_1)
	
	vim.api.nvim_buf_set_lines(ui.window.bufnr, ui.window_height, ui.window_height, false, {""})
end

--- Close the window
function ui.close_window()
	vim.api.nvim_del_autocmd(ui.cursor_moved_id)
	vim.api.nvim_del_autocmd(ui.cursor_moved_i_id)
	plenary_window.try_close(ui.window.win_id)
	ui.window = {
		win_id = nil
	}
	vim.cmd('stopinsert')
end

--- Toggle the window
function ui.toggle_window(Module)
	if ui.window.win_id then
		ui.close_window()
	else
		ui.old_cursor_pos = vim.api.nvim_win_get_cursor(0)
		ui.selected_buffer = vim.api.nvim_get_current_buf()
		ui.tab_string = Module.utils.get_tab_string()
		ui.create_window(Module)
		ui.draw_initial_window(Module)

		ui.cursor_moved_id = vim.api.nvim_create_autocmd("CursorMoved",
			{
				callback = function()
					ui.update_cursor(Module)
				end,
			}
		)

		ui.cursor_moved_i_id = vim.api.nvim_create_autocmd("CursorMovedI",
			{
				callback = function()
					ui.update_cursor(Module)
				end,
			}
		)

		--- Bind closing commands
		vim.api.nvim_buf_set_keymap(ui.window.bufnr, "i", "<Esc>", "<cmd>UESnip<CR>", { silent=false })

		--- Bind input commands
		vim.api.nvim_buf_set_keymap(ui.window.bufnr, "i", "<CR>", "<Cmd>lua local mod = require('nvim-ue5') mod.snippets.ui.handle_enter(mod)<CR>", { noremap=true, silent=true})

		--- Set the cursor
		---vim.api.nvim_win_set_cursor(0, {-2, 0})
		vim.cmd('startinsert')
		ui.current_state = 'initial'
		ui.type = 'generic'
		ui.update_question_text(Module)
	end
end

--- We only want the cursor to be on a certain line, so that we don't have to worry about readonly states
function ui.update_cursor(Module)
	local cursor_pos = vim.api.nvim_win_get_cursor(0)

	if ui.default_cursor_line ~= cursor_pos[1] then
		vim.api.nvim_win_set_cursor(0, {ui.default_cursor_line, 0})
	end
end

ui.state_questions = {
	initial = 'Enter the snippet type you want to generate: [1](O)bject, [2](A)ctor, [3](S)truct or [4](I)nterface',	
	final = 'Are you sure? [Y/n]',
}

ui.object_state_questions = {
	name = 'Enter UObject Class Name (Omitting the U prefix)',
	params = 'Enter the UObject Class Macro Parameters',
	parents = 'Enter the UObject Class Parents (Defaults to UObject)',
}

ui.actor_state_questions = {
	actor_name = 'Enter AActor Class Name (Omitting the A prefix)',
	actor_params = 'Enter the AActor Class Macro Parameters',
	actor_parents = 'Enter the AActor Class Parents (Defaults to AActor)',
}

ui.struct_state_questions = {
	struct_name = 'Enter the FStruct Name (Omitting the F prefix)',
	struct_params = 'Enter the FStruct Macro Parameters',
	struct_parents = 'Enter the FStruct Parents (Defaults to nil)',
}

ui.interface_state_questions = {
	interface_name = 'Enter UInterface and IInterface Class Name (Omitting the U/I prefix)',
}

function ui.update_state(Module, new_state)
	ui.current_state = new_state
	ui.update_preview(Module, ui.preview_table)
	ui.update_question_text(Module)
	ui.clear_input(Module)
end

--- Handle the enter key being pressed
function ui.handle_enter(Module)
	local input = vim.api.nvim_buf_get_lines(ui.window.bufnr, ui.window_height-1, ui.window_height, false)[1]

	if ui.current_state == 'initial' then
		local first_char = input:sub(1, 1)
		if first_char == '1' or first_char == 'O' or first_char == 'o' then
			ui.preview_table = {
				name = "Preview",
				params = "",
				parents = "UObject",
			}
			ui.type = 'object'
		elseif first_char == '2' or first_char == 'A' or first_char == 'a' then
			ui.preview_table = {
				name = "Preview",
				params = "",
				parents = "AActor",
			}
			ui.type = 'actor'
		elseif first_char == '3' or first_char == 'S' or first_char == 's' then
			ui.preview_table = {
				name = "Preview",
				params = "",
				parents = "",
			}
			ui.type = 'struct'
		elseif first_char == '4' or first_char == 'I' or first_char == 'i' then
			ui.preview_table = {
				name = 'Preview',
				params = '',
				parents_1 = 'UInterface',
				parents_2 = ''
			}
			ui.type = 'interface'
		end
		vim.defer_fn(function() ui.update_state(Module, 'name') end, 20)
		return
	elseif ui.current_state == 'name' then
		ui.preview_table.name = input
		vim.defer_fn(function() ui.update_state(Module, 'params') end, 20)
		return
	elseif ui.current_state == 'params' then
		ui.preview_table.params = input
		local next_state = ''
		if ui.type == 'interface' then
			next_state = 'parents_1'
		else
			next_state = 'parents'
		end
		vim.defer_fn(function() ui.update_state(Module, next_state) end, 20)
		return
	elseif ui.current_state == 'parents' or ui.current_state == 'parents_2' then
		ui.preview_table.parents = input
		vim.defer_fn(function() ui.update_state(Module, 'final') end, 20)
		return
	elseif ui.current_state == 'parents_1' then
		ui.preview_table.parents_1 = input
		vim.defer_fn(function() ui.update_state(Module, 'parents_2') end, 20)
		return
	elseif ui.current_state == 'final' then
		local first_char = input:sub(1, 1)
		if first_char == 'N' or first_char == 'n' then
			ui.toggle_window()
		elseif first_char == 'Y' or first_char == 'y' then
			local generated_snippet = {}
			if ui.type == 'object' then
				generated_snippet = Module.snippets.modules['uclass'].build_table(Module,
					{
						name = ui.preview_table.name,
						params = Module.snippets.parse_macro_parameters_string(Module, ui.preview_table.params),
						parents = Module.utils.parse_comma_seperated(Module, ui.preview_table.parents),
					}
				)
				Module.snippets.modules['uclass'].apply_tab_string(Module, ui.tab_string, generated_snippet)
			elseif ui.type == 'actor' then
				generated_snippet = Module.snippets.modules['aactor'].build_table(Module,
					{
						name = ui.preview_table.name,
						params = Module.snippets.parse_macro_parameters_string(Module, ui.preview_table.params),
						parents = Module.utils.parse_comma_seperated(Module, ui.preview_table.parents),
					}
				)
				Module.snippets.modules['aactor'].apply_tab_string(Module, ui.tab_string, generated_snippet)
			elseif ui.type == 'struct' then
				generated_snippet = Module.snippets.modules['fstruct'].build_table(Module,
					{
						name = ui.preview_table.name,
						params = Module.snippets.parse_macro_parameters_string(Module, ui.preview_table.params),
						parents = Module.utils.parse_comma_seperated(Module, ui.preview_table.parents),
					}
				)
				Module.snippets.modules['fstruct'].apply_tab_string(Module, ui.tab_string, generated_snippet)
			elseif ui.type == 'interface' then
				generated_snippet = Module.snippets.modules['interface'].build_table(Module, 
					{
						name = ui.preview_table.name,
						params = Module.snippets.parse_macro_parameters_string(Module, ui.preview_table.params),
						parents_1 = Module.utils.parse_comma_seperated(Module, ui.preview_table.parents_1),
						parents_2 = Module.utils.parse_comma_seperated(Module, ui.preview_table.parents_2),
					}
				)
				Module.snippets.modules['interface'].apply_tab_string(Module, ui.tab_string, generated_snippet)
			end
			vim.api.nvim_buf_set_lines(ui.selected_buffer, ui.old_cursor_pos[1]-1, ui.old_cursor_pos[1], false, generated_snippet)
			ui.toggle_window()
		end
	end
end

--- Set the current question text
function ui.update_question_text(Module)
	local text = ''

	if ui.current_state == 'initial' or ui.current_state == 'final' then
		text = ui.state_questions[ui.current_state]
	elseif ui.type == 'object' then
		text = ui.object_state_questions[ui.current_state]
	elseif ui.type == 'actor' then
		text = ui.actor_state_questions[ui.current_state]
	elseif ui.type == 'struct' then
		text = ui.struct_state_questions[ui.current_state]
	elseif ui.type == 'interface' then
		text = ui.interface_state_questions[ui.current_state]
	end
	vim.api.nvim_buf_set_lines(ui.window.bufnr, ui.window_height-3, ui.window_height-2, false, {text})
end

function ui.update_preview(Module, preview_table)
	local text_table = ''
	if ui.type == 'object' then
		text_table = Module.snippets.modules['uclass'].build_table(Module, 
			{
				name = preview_table.name,
				params = Module.snippets.parse_macro_parameters_string(Module, preview_table.params),
				parents = Module.utils.parse_comma_seperated(Module, preview_table.parents),
			}
		)
	elseif ui.type == 'actor' then
		text_table = Module.snippets.modules['aactor'].build_table(Module,
			{
				name = preview_table.name,
				params = Module.snippets.parse_macro_parameters_string(Module, preview_table.params),
				parents = Module.utils.parse_comma_seperated(Module, preview_table.parents),
			}
		)
	elseif ui.type == 'struct' then
		text_table = Module.snippets.modules['fstruct'].build_table(Module,
			{
				name = preview_table.name,
				params = Module.snippets.parse_macro_parameters_string(Module, preview_table.params),
				parents = Module.utils.parse_comma_seperated(Module, preview_table.parents),
			}
		)
	elseif ui.type == 'interface' then
		text_table = Module.snippets.modules['interface'].build_table(Module,
			{
				name = preview_table.name,
				params = Module.snippets.parse_macro_parameters_string(Module, preview_table.params),
				parents_1 = Module.utils.parse_comma_seperated(Module, preview_table.parents_1),
				parents_2 = Module.utils.parse_comma_seperated(Module, preview_table.parents_2),
			}
		)
	else
		return
	end
	vim.api.nvim_buf_set_lines(ui.window.bufnr, 3, 3+#text_table, false, text_table)
end

--- If a string is 8 characters or larger, when we get rid of it it makes a new line
--- We delete 4 characters at a time, and for some reason that is ok?!
--- Deleting 5 characters at a time will create a new line too
function ui.clear_input(Module)
	local input = vim.api.nvim_buf_get_lines(ui.window.bufnr, ui.window_height-1, ui.window_height, false)[1]
	local new_line = string.sub(input, 1, -5)

	vim.api.nvim_buf_set_lines(ui.window.bufnr, -2, -1, false, {new_line})

	if #new_line > 0 then
		vim.defer_fn(function() ui.clear_input(Module) end, 1)
	end
end

--- Return Module
return ui
