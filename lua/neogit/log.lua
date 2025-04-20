-- lua/neogit/log.lua
local M = {}
local git = require("neogit.git")
local utils = require("neogit.utils")
local config = require("neogit.config")

-- Buffer state
local state = {
    buffer = nil,
    window = nil,
}

-- Show git log
function M.show()
    -- Create buffer if it doesn't exist
    if not state.buffer or not vim.api.nvim_buf_is_valid(state.buffer) then
        state.buffer = utils.create_buffer("NeoGitLog", {
            filetype = "neogit-log",
            modifiable = false,
        })
    end

    -- Create or focus window
    if not state.window or not vim.api.nvim_win_is_valid(state.window) then
        state.window = utils.open_buffer(state.buffer, "split", 0.5)
    else
        vim.api.nvim_set_current_win(state.window)
    end

    -- Update log content
    update_log_content()

    -- Set up keymaps
    setup_keymaps()
end

-- Update log buffer content
local function update_log_content()
    local buf = state.buffer
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    -- Get log information
    local count = config.values.status.recent_commit_count or 10
    local log_output = git.log(count)

    if not log_output then
        return
    end

    -- Format log output
    vim.api.nvim_buf_set_option(buf, "modifiable", true)

    local lines = { "Commit History", "==============", "" }

    for _, line in ipairs(log_output) do
        local hash, author, date, subject = line:match("([^|]+)|([^|]+)|([^|]+)|(.+)")

        if hash and author and date and subject then
            table.insert(lines, hash .. " - " .. subject)
            table.insert(lines, "  Author: " .. author .. ", " .. date)
            table.insert(lines, "")
        end
    end

    table.insert(lines, "Press q to close, d to view diff of commit under cursor")

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Set up keymaps for log buffer
local function setup_keymaps()
    local buf = state.buffer
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    local function map(key, callback, desc)
        vim.api.nvim_buf_set_keymap(buf, "n", key, "", {
            callback = callback,
            noremap = true,
            silent = true,
            desc = desc,
        })
    end

    -- Close buffer
    map("q", function()
        vim.api.nvim_win_close(state.window, true)
    end, "Close")

    -- View commit diff
    map("d", function()
        local line = vim.api.nvim_get_current_line()
        local hash = line:match("^([0-9a-f]+) ")

        if hash then
            -- Show diff for this commit
            require("neogit.diff").show_commit(hash)
        end
    end, "View diff")
end

return M
