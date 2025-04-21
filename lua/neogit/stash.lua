-- lua/neogit/stash.lua
local M = {}
local git = require("neogit.git")
local ui = require("neogit.ui.buffers")
local utils = require("neogit.utils")

-- Get list of stashes
local function get_stashes()
	local output = git.command({ "stash", "list" })
	local stashes = {}

	if output then
		for i, line in ipairs(output) do
			local stash_name, description = line:match("(stash@{%d+}): (.+)")

			if stash_name and description then
				table.insert(stashes, {
					index = i - 1,
					name = stash_name,
					description = description,
				})
			end
		end
	end

	return stashes
end

-- Show stash operations menu
function M.menu()
	local options = {
		{ text = "List stashes", value = "list" },
		{ text = "Create new stash", value = "create" },
		{ text = "Apply stash", value = "apply" },
		{ text = "Pop stash", value = "pop" },
		{ text = "Drop stash", value = "drop" },
	}

	ui.create_menu("Stash Operations", options, function(choice)
		if choice == "list" then
			M.list()
		elseif choice == "create" then
			M.create()
		elseif choice == "apply" then
			M.apply_menu()
		elseif choice == "pop" then
			M.pop_menu()
		elseif choice == "drop" then
			M.drop_menu()
		end
	end)
end

-- List stashes
function M.list()
	local stashes = get_stashes()

	-- Create buffer
	local buf = utils.create_buffer("NeoGitStashes", {
		filetype = "neogit-stashes",
		modifiable = false,
		bufhidden = "wipe",
	})

	-- Set content
	vim.api.nvim_buf_set_option(buf, "modifiable", true)

	local lines = { "Stashes", "=======", "" }

	if #stashes == 0 then
		table.insert(lines, "No stashes found")
	else
		for _, stash in ipairs(stashes) do
			table.insert(lines, stash.name .. ": " .. stash.description)
		end
	end

	table.insert(lines, "")
	table.insert(lines, "Press q to close")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	-- Open in a floating window
	local win = utils.open_buffer(buf, "float", 0.4)

	-- Add keymap to close
	vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
		callback = function()
			vim.api.nvim_win_close(win, true)
		end,
		noremap = true,
		silent = true,
	})
end

-- Create a new stash
function M.create()
	-- Ask for stash message
	vim.ui.input({ prompt = "Stash message (optional): " }, function(message)
		local args = { "stash", "push" }

		if message and message ~= "" then
			table.insert(args, "-m")
			table.insert(args, message)
		end

		local result = git.command(args)

		if result then
			vim.notify("Created new stash", vim.log.levels.INFO)
			-- Refresh status buffer
			require("neogit.status").refresh()
		end
	end)
end

-- Apply stash menu
function M.apply_menu()
	local stashes = get_stashes()

	if #stashes == 0 then
		vim.notify("No stashes found", vim.log.levels.INFO)
		return
	end

	local options = {}

	for _, stash in ipairs(stashes) do
		table.insert(options, { text = stash.description, value = stash.name })
	end

	ui.create_menu("Apply Stash", options, function(stash_name)
		if stash_name then
			local result = git.command({ "stash", "apply", stash_name })

			if result then
				vim.notify("Applied stash: " .. stash_name, vim.log.levels.INFO)
				-- Refresh status buffer
				require("neogit.status").refresh()
			end
		end
	end)
end

-- Pop stash menu
function M.pop_menu()
	local stashes = get_stashes()

	if #stashes == 0 then
		vim.notify("No stashes found", vim.log.levels.INFO)
		return
	end

	local options = {}

	for _, stash in ipairs(stashes) do
		table.insert(options, { text = stash.description, value = stash.name })
	end

	ui.create_menu("Pop Stash", options, function(stash_name)
		if stash_name then
			local result = git.command({ "stash", "pop", stash_name })

			if result then
				vim.notify("Popped stash: " .. stash_name, vim.log.levels.INFO)
				-- Refresh status buffer
				require("neogit.status").refresh()
			end
		end
	end)
end

-- Drop stash menu
function M.drop_menu()
	local stashes = get_stashes()

	if #stashes == 0 then
		vim.notify("No stashes found", vim.log.levels.INFO)
		return
	end

	local options = {}

	for _, stash in ipairs(stashes) do
		table.insert(options, { text = stash.description, value = stash.name })
	end

	ui.create_menu("Drop Stash", options, function(stash_name)
		if stash_name then
			-- Confirm deletion
			vim.ui.select({ "Yes", "No" }, {
				prompt = "Are you sure you want to drop stash " .. stash_name .. "?",
			}, function(choice)
				if choice == "Yes" then
					local result = git.command({ "stash", "drop", stash_name })

					if result then
						vim.notify("Dropped stash: " .. stash_name, vim.log.levels.INFO)
					end
				end
			end)
		end
	end)
end

return M
