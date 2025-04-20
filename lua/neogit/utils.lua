-- lua/neogit/utils.lua
local M = {}

-- Split string by separator
function M.split(str, sep)
    local result = {}
    local pattern = string.format("([^%s]+)", sep)

    for match in string.gmatch(str, pattern) do
        table.insert(result, match)
    end

    return result
end

-- Convert git status code to human-readable text
function M.status_to_text(status)
    local codes = {
        ["M"] = "Modified",
        ["A"] = "Added",
        ["D"] = "Deleted",
        ["R"] = "Renamed",
        ["C"] = "Copied",
        ["U"] = "Updated but unmerged",
        ["?"] = "Untracked",
        ["!"] = "Ignored",
    }

    return codes[status] or status
end

-- Create a new buffer
function M.create_buffer(name, options)
    options = options or {}

    -- Create buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set buffer name
    if name then
        vim.api.nvim_buf_set_name(buf, name)
    end

    -- Set buffer options
    local default_options = {
        buftype = "nofile",
        swapfile = false,
        modifiable = true,
        filetype = "neogit",
        bufhidden = "hide",
    }

    for k, v in pairs(vim.tbl_deep_extend("force", default_options, options)) do
        vim.api.nvim_buf_set_option(buf, k, v)
    end

    return buf
end

-- Open a buffer in a split or reuse existing one
function M.open_buffer(buf, type, size)
    type = type or "split"
    size = size or 0.4

    -- Get current window dimensions
    local win_width = vim.api.nvim_get_option("columns")
    local win_height = vim.api.nvim_get_option("lines")

    -- Calculate new window size
    local width = math.floor(win_width * size)
    local height = math.floor(win_height * size)

    -- Set window options based on type
    local win_opts = {}

    if type == "split" then
        vim.cmd(height .. "split")
    elseif type == "vsplit" then
        vim.cmd(width .. "vsplit")
    elseif type == "float" then
        win_opts = {
            relative = "editor",
            width = width,
            height = height,
            col = math.floor((win_width - width) / 2),
            row = math.floor((win_height - height) / 2),
            style = "minimal",
            border = "rounded",
        }
    end

    local win

    if type == "float" then
        win = vim.api.nvim_open_win(buf, true, win_opts)
    else
        -- For split/vsplit, switch to the window and set the buffer
        win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(win, buf)
    end

    return win
end

return M
