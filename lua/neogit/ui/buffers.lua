-- lua/neogit/ui/buffers.lua
local M = {}
local utils = require("neogit.utils")

-- Setup highlight groups (blue for title, cyan for separator)
local function setup_neogit_highlights()
    vim.api.nvim_set_hl(0, "NeoGitTitle", { fg = "#61afef", bold = true })
    vim.api.nvim_set_hl(0, "NeoGitSeparator", { fg = "#56b6c2", bold = true })
    vim.api.nvim_set_hl(0, "NeoGitStaged", { fg = "#98c379", bold = true }) -- Green
    vim.api.nvim_set_hl(0, "NeoGitUnstaged", { fg = "#e06c75", bold = true }) -- Red
    vim.api.nvim_set_hl(0, "NeoGitBranch", { fg = "#c678dd", bold = true }) -- Purple
    vim.api.nvim_set_hl(0, "NeoGitProject", { fg = "#e5c07b", bold = true }) -- Yellow
end
setup_neogit_highlights()

-- Re-apply highlights after colorscheme changes
vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = setup_neogit_highlights,
})

-- Help buffer state
local help_state = {
    buffer = nil,
    window = nil,
}

-- Show a popup with help text
function M.show_help(help_lines)
    -- Close existing help window if it exists
    if help_state.window and vim.api.nvim_win_is_valid(help_state.window) then
        vim.api.nvim_win_close(help_state.window, true)
        help_state.window = nil
    end

    -- Create help buffer
    help_state.buffer = utils.create_buffer("NeoGitHelp", {
        filetype = "neogit-help",
        modifiable = false,
        bufhidden = "wipe",
    })

    -- Set help content
    vim.api.nvim_buf_set_option(help_state.buffer, "modifiable", true)

    local lines = { "NeoGit Help", "==========", "" }

    for _, line in ipairs(help_lines) do
        table.insert(lines, line)
    end

    table.insert(lines, "")
    table.insert(lines, "Press q to close this help window")

    vim.api.nvim_buf_set_lines(help_state.buffer, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(help_state.buffer, "modifiable", false)

    -- Highlight title and separator
    vim.api.nvim_buf_add_highlight(help_state.buffer, -1, "NeoGitTitle", 0, 0, -1)
    vim.api.nvim_buf_add_highlight(help_state.buffer, -1, "NeoGitSeparator", 1, 0, -1)

    -- Open in a floating window
    help_state.window = utils.open_buffer(help_state.buffer, "float", 0.4)

    -- Add keymap to close
    vim.api.nvim_buf_set_keymap(help_state.buffer, "n", "q", "", {
        callback = function()
            vim.api.nvim_win_close(help_state.window, true)
            help_state.window = nil
        end,
        noremap = true,
        silent = true,
    })
end

-- Create a menu buffer with options
function M.create_menu(title, options, callback)
    -- Create buffer
    local buf = utils.create_buffer("NeoGitMenu", {
        filetype = "neogit-menu",
        modifiable = false,
        bufhidden = "wipe",
    })

    -- Set content
    vim.api.nvim_buf_set_option(buf, "modifiable", true)

    local lines = { title, string.rep("=", string.len(title)), "" }

    for i, option in ipairs(options) do
        table.insert(lines, string.format("%d. %s", i, option.text))
    end

    table.insert(lines, "")
    table.insert(lines, "Enter a number to select, or press q to cancel")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)

    -- Highlight title and separator
    vim.api.nvim_buf_add_highlight(buf, -1, "NeoGitTitle", 0, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, -1, "NeoGitSeparator", 1, 0, -1)

    -- Open in a floating window
    local win = utils.open_buffer(buf, "float", 0.4)

    -- Set up keymaps
    for i, option in ipairs(options) do
        local key = tostring(i)
        vim.api.nvim_buf_set_keymap(buf, "n", key, "", {
            callback = function()
                vim.api.nvim_win_close(win, true)
                callback(option.value or i)
            end,
            noremap = true,
            silent = true,
        })
    end

    -- Add keymap to close
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
        callback = function()
            vim.api.nvim_win_close(win, true)
        end,
        noremap = true,
        silent = true,
    })

    return buf, win
end

return M
