-- lua/neogit/status.lua
local M = {}
local git = require("neogit.git")
local utils = require("neogit.utils")
local config = require("neogit.config")
local ui = require("neogit.ui.buffers")

-- Buffer state
local state = {
    buffer = nil,
    window = nil,
}
M.__private_state = state

local function create_status_buffer()
    -- Create buffer if it doesn't exist
    if not state.buffer or not vim.api.nvim_buf_is_valid(state.buffer) then
        state.buffer = utils.create_buffer("NeoGit", {
            filetype = "neogit-status",
            modifiable = false,
        })
    end

    -- Create or focus window
    if not state.window or not vim.api.nvim_win_is_valid(state.window) then
        state.window = utils.open_buffer(state.buffer, "split", 0.5)
    else
        vim.api.nvim_set_current_win(state.window)
    end

    return state.buffer
end

-- Update status buffer content
function M.update_status_content()
    local buf = state.buffer
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    local status = git.status()
    if not status then
        return
    end

    vim.api.nvim_buf_set_option(buf, "modifiable", true)

    -- Prepare content lines
    local lines = {}

    -- Header
    table.insert(lines, "NeoGit: " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":~"))
    table.insert(lines, "Branch: " .. status.branch)
    table.insert(lines, "")

    -- Sections
    -- Staged changes
    table.insert(lines, "Staged changes:")
    if #status.staged == 0 then
        table.insert(lines, "  No staged changes")
    else
        for _, item in ipairs(status.staged) do
            local status_text = utils.status_to_text(item.status:sub(1, 1))
            table.insert(lines, "  " .. status_text .. ": " .. item.path)
        end
    end
    table.insert(lines, "")

    -- Unstaged changes
    table.insert(lines, "Unstaged changes:")
    if #status.unstaged == 0 then
        table.insert(lines, "  No unstaged changes")
    else
        for _, item in ipairs(status.unstaged) do
            local status_text = utils.status_to_text(item.status:sub(2, 2))
            table.insert(lines, "  " .. status_text .. ": " .. item.path)
        end
    end
    table.insert(lines, "")

    -- Untracked files
    table.insert(lines, "Untracked files:")
    if #status.untracked == 0 then
        table.insert(lines, "  No untracked files")
    else
        for _, item in ipairs(status.untracked) do
            table.insert(lines, "  " .. item.path)
        end
    end
    table.insert(lines, "")

    -- Help text
    table.insert(lines, "Press ? for help")

    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)

    -- Highlight project and branch lines
    vim.api.nvim_buf_add_highlight(buf, -1, "NeoGitProject", 0, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, -1, "NeoGitBranch", 1, 0, -1)
    -- Highlight section headers and file lines
    local section = nil
    for i, line in ipairs(lines) do
        if line:match("^Staged changes:") then
            vim.api.nvim_buf_add_highlight(buf, -1, "NeoGitTitle", i-1, 0, -1)
            section = "staged"
        elseif line:match("^Unstaged changes:") then
            vim.api.nvim_buf_add_highlight(buf, -1, "NeoGitTitle", i-1, 0, -1)
            section = "unstaged"
        elseif line:match("^Untracked files:") then
            vim.api.nvim_buf_add_highlight(buf, -1, "NeoGitTitle", i-1, 0, -1)
            section = "untracked"
        elseif line:match("^$") then
            section = nil
        elseif line:match("^  .-: .+") and section == "staged" then
            vim.api.nvim_buf_add_highlight(buf, -1, "NeoGitStaged", i-1, 0, -1)
        elseif line:match("^  .-: .+") and section == "unstaged" then
            vim.api.nvim_buf_add_highlight(buf, -1, "NeoGitUnstaged", i-1, 0, -1)
        end
    end

end

-- Set up keymaps for status buffer
function M.setup_keymaps()
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

    -- Basic operations
    map("s", function()
        -- Stage item under cursor
        local line = vim.api.nvim_get_current_line()
        local file = line:match(": (.+)$") or line:match("^%s%s(.+)$")

        if file then
            git.stage(file)
            M.update_status_content()
            vim.notify("Staged: " .. file)
        end
    end, "Stage file")

    map("u", function()
        -- Unstage item under cursor
        local line = vim.api.nvim_get_current_line()
        local file = line:match(": (.+)$")

        if file then
            git.unstage(file)
            M.update_status_content()
            vim.notify("Unstaged: " .. file)
        end
    end, "Unstage file")

    map("c", function()
        -- Open commit buffer in the same window
        require("neogit.commit").create(state.window)
    end, "Commit")

    local function push_selected_branch()
        local branches = git.branches()
        local branch_names = {}
        for _, branch in ipairs(branches) do
            table.insert(branch_names, branch.name)
        end
        vim.ui.select(branch_names, { prompt = "Select branch to push:" }, function(selected)
            if selected then
                git.push(nil, selected)
                vim.notify("Pushed branch: " .. selected)
                M.update_status_content()
            end
        end)
    end
    map("p", push_selected_branch, "Push")


    map("f", function()
        -- Fetch from remote
        git.command({ "fetch" })
        vim.notify("Fetched from remote")
        M.update_status_content()
    end, "Fetch")

    map("r", function()
        -- Pull from remote
        git.pull()
        vim.notify("Pulled from remote")
        M.update_status_content()
    end, "Pull")

    map("b", function()
        -- Branch operations menu
        require("neogit.branch").menu()
    end, "Branch operations")

    map("z", function()
        -- Stash operations menu
        require("neogit.stash").menu()
    end, "Stash operations")

    map("S", function()
        -- Stage all files (unstaged + untracked)
        local status = git.status()
        local staged_any = false
        if status then
            -- Stage unstaged
            for _, item in ipairs(status.unstaged or {}) do
                if item.path then
                    git.stage(item.path)
                    staged_any = true
                end
            end
            -- Stage untracked
            for _, item in ipairs(status.untracked or {}) do
                if item.path then
                    git.stage(item.path)
                    staged_any = true
                end
            end
        end
        M.update_status_content()
        if staged_any then
            vim.notify("Staged all unstaged and untracked files")
        else
            vim.notify("No files to stage", vim.log.levels.INFO)
        end
    end, "Stage all files")

    map("?", function()
        -- Show help
        ui.show_help({
            "s - Stage file/hunk under cursor",
            "u - Unstage file/hunk under cursor",
            "c - Commit staged changes",
            "p - Push to remote",
            "f - Fetch from remote",
            "r - Pull (rebase) from remote",
            "b - Branch operations menu",
            "z - Stash operations menu",
            "S - Stash all changes (staged & unstaged)",
            "? - Show this help",
            "q - Close NeoGit buffer",
        })
    end, "Help")

    map("q", function()
        -- Close buffer
        vim.api.nvim_win_close(state.window, true)
    end, "Quit")

    -- Auto refresh on focus
    if config.values.auto_refresh then
        vim.api.nvim_create_autocmd({ "BufEnter" }, {
            buffer = buf,
            callback = function()
                M.update_status_content()
            end,
        })
    end
end

-- Create status buffer and update content
function M.create()
    create_status_buffer()
    M.update_status_content()
    M.setup_keymaps()
end

-- Refresh status buffer
function M.refresh()
    M.update_status_content()
end

M._push_selected_branch = function()
    local branches = git.branches()
    local branch_names = {}
    for _, branch in ipairs(branches) do
        table.insert(branch_names, branch.name)
    end
    vim.ui.select(branch_names, { prompt = "Select branch to push:" }, function(selected)
        if selected then
            git.push(nil, selected)
            vim.notify("Pushed branch: " .. selected)
            M.update_status_content()
        end
    end)
end

return M
