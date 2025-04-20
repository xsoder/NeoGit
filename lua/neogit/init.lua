-- lua/neogit/init.lua
local M = {}
local config = require("neogit.config")
local status = require("neogit.status")
local commit = require("neogit.commit")
local log = require("neogit.log")
local git = require("neogit.git")

function M.setup(user_config)
    config.setup(user_config)

    -- Create user commands
    vim.api.nvim_create_user_command("NeoGit", function()
        M.open()
    end, {})

    vim.api.nvim_create_user_command("NeoGitCommit", function()
        commit.create()
    end, {})

    vim.api.nvim_create_user_command("NeoGitPush", function()
        git.push()
    end, {})

    vim.api.nvim_create_user_command("NeoGitPull", function()
        git.pull()
    end, {})

    vim.api.nvim_create_user_command("NeoGitLog", function()
        log.show()
    end, {})
end

function M.open()
    -- Check if git repo
    if not git.is_git_repo() then
        vim.notify("Not a git repository", vim.log.levels.ERROR)
        return
    end

    -- Open the status buffer
    status.create()
end

return M
