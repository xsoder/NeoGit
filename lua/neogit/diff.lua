-- lua/neogit/diff.lua
local M = {}
local git = require("neogit.git")
local utils = require("neogit.utils")

-- Buffer state
local state = {
    buffer = nil,
    window = nil,
}

-- Show diff for a file
function M.show_file(file, staged)
    -- Create buffer
    local buf = utils.create_buffer("NeoGitDiff", {
        filetype = "diff",
        modifiable = false,
        bufhidden = "wipe",
    })

    -- Get diff
    local diff = git.diff(file, staged)

    -- Set content
    vim.api.nvim_buf_set_option(buf, "modifiable", true)

    local title = "Diff for " .. file
    local lines = { title, string.rep("=", string.len(title)), "" }

    if diff and #diff > 0 then
        for _, line in ipairs(diff) do
            table.insert(lines, line)
        end
    else
        table.insert(lines, "No differences found")
    end

    table.insert(lines, "")
    table.insert(lines, "Press q to close")

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)

    -- Open in a split
    local win = utils.open_buffer(buf, "split", 0.5)

    -- Add keymap to close
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
        callback = function()
            vim.api.nvim_win_close(win, true)
        end,
        noremap = true,
        silent = true,
    })
end

-- Show diff for a commit
function M.show_commit(hash)
    -- Create buffer
    local buf = utils.create_buffer("NeoGitCommitDiff", {
        filetype = "diff",
        modifiable = false,
        bufhidden = "wipe",
    })

    -- Get commit info
    local commit_info = git.command({ "show", "--pretty=format:%h %s%n%an <%ae>%n%ai", hash })

    if not commit_info then
        return
    end

    -- Set content
    vim.api.nvim_buf_set_option(buf, "modifiable", true)

    local lines = {}

    if commit_info and #commit_info > 0 then
        for _, line in ipairs(commit_info) do
            table.insert(lines, line)
        end
    else
        table.insert(lines, "No commit information found")
    end

    table.insert(lines, "")
    table.insert(lines, "Press q to close")

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)

    -- Open in a split
    local win = utils.open_buffer(buf, "split", 0.5)

    -- Add keymap to close
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
        callback = function()
            vim.api.nvim_win_close(win, true)
        end,
        noremap = true,
        silent = true,
    })
end

return M
