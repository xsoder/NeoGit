-- lua/neogit/remote.lua
local M = {}
local git = require("neogit.git")
local ui = require("neogit.ui.buffers")
local utils = require("neogit.utils")

-- Get list of remotes
local function get_remotes()
    local output = git.command({ "remote", "-v" })
    local remotes = {}
    local seen = {}

    if output then
        for _, line in ipairs(output) do
            local name, url = line:match("([^%s]+)%s+([^%s]+)")

            if name and url and not seen[name] then
                seen[name] = true
                table.insert(remotes, {
                    name = name,
                    url = url,
                })
            end
        end
    end

    return remotes
end

-- Show remote operations menu
function M.menu()
    local options = {
        { text = "List remotes",      value = "list" },
        { text = "Add remote",        value = "add" },
        { text = "Remove remote",     value = "remove" },
        { text = "Push to remote",    value = "push" },
        { text = "Fetch from remote", value = "fetch" },
        { text = "Pull from remote",  value = "pull" },
    }

    ui.create_menu("Remote Operations", options, function(choice)
        if choice == "list" then
            M.list()
        elseif choice == "add" then
            M.add()
        elseif choice == "remove" then
            M.remove_menu()
        elseif choice == "push" then
            M.push_menu()
        elseif choice == "fetch" then
            M.fetch_menu()
        elseif choice == "pull" then
            M.pull_menu()
        end
    end)
end

-- List remotes
function M.list()
    local remotes = get_remotes()

    -- Create buffer
    local buf = utils.create_buffer("NeoGitRemotes", {
        filetype = "neogit-remotes",
        modifiable = false,
        bufhidden = "wipe",
    })

    -- Set content
    vim.api.nvim_buf_set_option(buf, "modifiable", true)

    local lines = { "Remotes", "=======", "" }

    if #remotes == 0 then
        table.insert(lines, "No remotes found")
    else
        for _, remote in ipairs(remotes) do
            table.insert(lines, remote.name .. ": " .. remote.url)
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

-- Add remote
function M.add()
    -- Ask for remote name
    vim.ui.input({ prompt = "Remote name: " }, function(name)
        if not name or name == "" then
            vim.notify("Remote addition canceled", vim.log.levels.INFO)
            return
        end

        -- Ask for remote URL
        vim.ui.input({ prompt = "Remote URL: " }, function(url)
            if not url or url == "" then
                vim.notify("Remote addition canceled", vim.log.levels.INFO)
                return
            end

            local result = git.command({ "remote", "add", name, url })

            if result then
                vim.notify("Added remote: " .. name .. " -> " .. url, vim.log.levels.INFO)
            end
        end)
    end)
end

-- Remove remote menu
function M.remove_menu()
    local remotes = get_remotes()

    if #remotes == 0 then
        vim.notify("No remotes found", vim.log.levels.INFO)
        return
    end

    local options = {}

    for _, remote in ipairs(remotes) do
        table.insert(options, { text = remote.name .. " (" .. remote.url .. ")", value = remote.name })
    end

    ui.create_menu("Remove Remote", options, function(remote_name)
        if remote_name then
            -- Confirm deletion
            vim.ui.select({ "Yes", "No" }, {
                prompt = "Are you sure you want to remove remote " .. remote_name .. "?",
            }, function(choice)
                if choice == "Yes" then
                    local result = git.command({ "remote", "remove", remote_name })

                    if result then
                        vim.notify("Removed remote: " .. remote_name, vim.log.levels.INFO)
                    end
                end
            end)
        end
    end)
end

-- Push to remote menu
function M.push_menu()
    local remotes = get_remotes()

    if #remotes == 0 then
        vim.notify("No remotes found", vim.log.levels.INFO)
        return
    end

    local options = {}

    for _, remote in ipairs(remotes) do
        table.insert(options, { text = remote.name, value = remote.name })
    end

    ui.create_menu("Push to Remote", options, function(remote_name)
        if remote_name then
            local branches = git.branches()
            local current_branch = nil

            for _, branch in ipairs(branches) do
                if branch.current then
                    current_branch = branch.name
                    break
                end
            end

            if current_branch then
                local result = git.push(remote_name, current_branch)

                if result then
                    vim.notify("Pushed to remote: " .. remote_name .. "/" .. current_branch, vim.log.levels.INFO)
                end
            else
                vim.notify("No current branch found", vim.log.levels.ERROR)
            end
        end
    end)
end

-- Fetch from remote menu
function M.fetch_menu()
    local remotes = get_remotes()

    if #remotes == 0 then
        vim.notify("No remotes found", vim.log.levels.INFO)
        return
    end

    local options = {}

    for _, remote in ipairs(remotes) do
        table.insert(options, { text = remote.name, value = remote.name })
    end

    ui.create_menu("Fetch from Remote", options, function(remote_name)
        if remote_name then
            local result = git.command({ "fetch", remote_name })

            if result then
                vim.notify("Fetched from remote: " .. remote_name, vim.log.levels.INFO)
                -- Refresh status buffer
                require("neogit.status").refresh()
            end
        end
    end)
end

-- Pull from remote menu
function M.pull_menu()
    local remotes = get_remotes()

    if #remotes == 0 then
        vim.notify("No remotes found", vim.log.levels.INFO)
        return
    end

    local options = {}
    for _, remote in ipairs(remotes) do
        table.insert(options, { text = remote.name, value = remote.name })
    end

    ui.create_menu("Pull from Remote", options, function(remote_name)
        if not remote_name then return end
        -- Get remote branches using git ls-remote
        local output = git.command({ "ls-remote", '--heads', remote_name })
        if not output or #output == 0 then
            vim.notify("No branches found on remote " .. remote_name, vim.log.levels.INFO)
            return
        end
        local branch_options = {}
        for _, line in ipairs(output) do
            local hash, ref = line:match("(%w+)%s+refs/heads/(.+)")
            if ref then
                table.insert(branch_options, { text = ref, value = ref })
            end
        end
        if #branch_options == 0 then
            vim.notify("No branches found on remote " .. remote_name, vim.log.levels.INFO)
            return
        end
        ui.create_menu("Select branch to pull from", branch_options, function(branch_name)
            if branch_name then
                local result = git.pull(remote_name, branch_name)
                if result then
                    vim.notify("Pulled from " .. remote_name .. "/" .. branch_name, vim.log.levels.INFO)
                    require("neogit.status").refresh()
                end
            end
        end)
    end)
end

return M
