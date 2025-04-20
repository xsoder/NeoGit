-- lua/neogit/branch.lua
local M = {}
local git = require("neogit.git")
local ui = require("neogit.ui.buffers")
local utils = require("neogit.utils")

-- Show branch operations menu
function M.menu()
    local options = {
        { text = "List branches",     value = "list" },
        { text = "Create new branch", value = "create" },
        { text = "Checkout branch",   value = "checkout" },
        { text = "Delete branch",     value = "delete" },
        { text = "Merge branch",      value = "merge" },
    }

    ui.create_menu("Branch Operations", options, function(choice)
        if choice == "list" then
            M.list()
        elseif choice == "create" then
            M.create()
        elseif choice == "checkout" then
            M.checkout_menu()
        elseif choice == "delete" then
            M.delete_menu()
        elseif choice == "merge" then
            M.merge_menu()
        end
    end)
end

-- List branches
function M.list()
    local branches = git.branches()

    -- Create buffer
    local buf = utils.create_buffer("NeoGitBranches", {
        filetype = "neogit-branches",
        modifiable = false,
        bufhidden = "wipe",
    })

    -- Set content
    vim.api.nvim_buf_set_option(buf, "modifiable", true)

    local lines = { "Branches", "========", "" }

    for _, branch in ipairs(branches) do
        local prefix = branch.current and "* " or "  "
        table.insert(lines, prefix .. branch.name)
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

-- Create a new branch
function M.create()
    -- Ask for branch name
    vim.ui.input({ prompt = "New branch name: " }, function(name)
        if not name or name == "" then
            vim.notify("Branch creation canceled", vim.log.levels.INFO)
            return
        end

        -- Create branch
        local result = git.create_branch(name)

        if result then
            vim.notify("Created and checked out branch: " .. name, vim.log.levels.INFO)
            -- Refresh status buffer
            require("neogit.status").refresh()
        end
    end)
end

-- Checkout branch menu
function M.checkout_menu()
    local branches = git.branches()
    local options = {}

    for _, branch in ipairs(branches) do
        if not branch.current then
            table.insert(options, { text = branch.name, value = branch.name })
        end
    end

    if #options == 0 then
        vim.notify("No other branches to checkout", vim.log.levels.INFO)
        return
    end

    ui.create_menu("Checkout Branch", options, function(branch_name)
        if branch_name then
            git.checkout(branch_name)
            vim.notify("Checked out branch: " .. branch_name, vim.log.levels.INFO)
            -- Refresh status buffer
            require("neogit.status").refresh()
        end
    end)
end

-- Delete branch menu
function M.delete_menu()
    local branches = git.branches()
    local options = {}

    for _, branch in ipairs(branches) do
        if not branch.current then
            table.insert(options, { text = branch.name, value = branch.name })
        end
    end

    if #options == 0 then
        vim.notify("No branches available to delete", vim.log.levels.INFO)
        return
    end

    ui.create_menu("Delete Branch", options, function(branch_name)
        if branch_name then
            -- Confirm deletion
            vim.ui.select({ "Yes", "No" }, {
                prompt = "Are you sure you want to delete branch " .. branch_name .. "?",
            }, function(choice)
                if choice == "Yes" then
                    local result = git.delete_branch(branch_name)

                    if result then
                        vim.notify("Deleted branch: " .. branch_name, vim.log.levels.INFO)
                        -- Refresh status buffer
                        require("neogit.status").refresh()
                    end
                end
            end)
        end
    end)
end

-- Merge branch menu
function M.merge_menu()
    local branches = git.branches()
    local options = {}

    for _, branch in ipairs(branches) do
        if not branch.current then
            table.insert(options, { text = branch.name, value = branch.name })
        end
    end

    if #options == 0 then
        vim.notify("No branches available to merge", vim.log.levels.INFO)
        return
    end

    ui.create_menu("Merge Branch", options, function(branch_name)
        if branch_name then
            local result = git.command({ "merge", branch_name })

            if result then
                vim.notify("Merged branch: " .. branch_name, vim.log.levels.INFO)
                -- Refresh status buffer
                require("neogit.status").refresh()
            end
        end
    end)
end

return M
