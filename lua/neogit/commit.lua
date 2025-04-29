-- lua/neogit/commit.lua
local M = {}
local git = require("neogit.git")
local utils = require("neogit.utils")

-- Buffer state
local state = {
	buffer = nil,
}

-- Create a commit buffer
function M.create(parent_win)
	-- Create buffer
	state.buffer = utils.create_buffer("COMMIT_EDITMSG", {
		filetype = "gitcommit",
		modifiable = true,
		bufhidden = "wipe",
	})

	-- Open buffer in the given window (replace status buffer)
	if parent_win and vim.api.nvim_win_is_valid(parent_win) then
		vim.api.nvim_win_set_buf(parent_win, state.buffer)
		vim.api.nvim_set_current_win(parent_win)
		state.parent_win = parent_win
	else
		local win = utils.open_buffer(state.buffer, "split", 0.3)
		if win then
			vim.api.nvim_set_current_win(win)
		end
		state.parent_win = nil
	end

	-- Enter insert mode immediately
	vim.schedule(function()
		vim.cmd("startinsert")
	end)

	-- Add some help text to the buffer
	local function build_commit_message_lines()
		local lines = {
			"",
			"# Please enter the commit message for your changes. Lines starting",
			"# with '#' will be ignored, and an empty message aborts the commit.",
			"#",
			"# NeoGit: Press 'c' to commit or 'q' to cancel.",
		}

		-- Add status to commit message
		local status = git.status()
		if status then
			table.insert(lines, "#")
			table.insert(lines, "# Changes to be committed:")
			for _, item in ipairs(status.staged) do
				local status_text = utils.status_to_text(item.status:sub(1, 1))
				table.insert(lines, "#   " .. status_text .. ": " .. item.path)
			end
		end

		return lines
	end

	local lines = build_commit_message_lines()
	vim.api.nvim_buf_set_lines(state.buffer, 0, -1, false, lines)

	-- Set cursor to the first empty line (for commit message)
	local first_edit_line = 1
	for i, line in ipairs(lines) do
		if line == "" then
			first_edit_line = i
			break
		end
	end
	vim.api.nvim_win_set_cursor(0, { first_edit_line, 0 })

	-- Enter insert mode immediately after setting cursor
	vim.schedule(function()
		vim.cmd("startinsert")
	end)

	-- Set up keymaps
	local function map(key, callback, desc)
		vim.api.nvim_buf_set_keymap(state.buffer, "n", key, "", {
			callback = callback,
			noremap = true,
			silent = true,
			desc = desc,
		})
	end

	-- Commit on 'c'
	map("c", function()
		M.submit()
	end, "Submit commit")

	-- Cancel on 'q'
	map("q", function()
		M.cancel()
	end, "Cancel commit")
end

-- Submit the commit
function M.submit()
	if not state.buffer or not vim.api.nvim_buf_is_valid(state.buffer) then
		return
	end

	-- Get commit message lines
	local lines = vim.api.nvim_buf_get_lines(state.buffer, 0, -1, false)

	-- Filter out comment lines
	local message_lines = {}
	for _, line in ipairs(lines) do
		if not line:match("^%s*#") then
			table.insert(message_lines, line)
		end
	end

	-- Check if message is empty
	local message = table.concat(message_lines, "\n")
	message = message:gsub("^%s*(.-)%s*$", "%1") -- Trim

	if message == "" then
		vim.notify("Aborting commit due to empty commit message", vim.log.levels.WARN)
		vim.api.nvim_win_close(0, true)
		-- Restore status buffer if parent_win is available
		if state.parent_win and vim.api.nvim_win_is_valid(state.parent_win) then
			local status = require("neogit.status")
			vim.api.nvim_win_set_buf(state.parent_win, status.__private_state.buffer)
			status.update_status_content()
		end
		return
	end

	-- Execute commit
	git.commit(message)

	-- Restore status buffer in the current window (do not close window)
	local status = require("neogit.status")
	local win = 0 -- current window
	if state.parent_win and vim.api.nvim_win_is_valid(state.parent_win) then
		win = state.parent_win
	end
	if vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_set_buf(win, status.__private_state.buffer)
		status.update_status_content()
	end
	vim.notify("Changes committed successfully")
end

-- Cancel the commit
function M.cancel()
	if not state.buffer or not vim.api.nvim_buf_is_valid(state.buffer) then
		return
	end

	vim.api.nvim_win_close(0, true)
	-- Restore status buffer in parent window
	if state.parent_win and vim.api.nvim_win_is_valid(state.parent_win) then
		local status = require("neogit.status")
		vim.api.nvim_win_set_buf(state.parent_win, status.__private_state.buffer)
		status.update_status_content()
	end
	vim.notify("Commit canceled")
end

return M
