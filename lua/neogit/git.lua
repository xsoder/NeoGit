-- lua/neogit/git.lua
local M = {}
local Job = require("plenary.job")
local utils = require("neogit.utils")

-- Run git command and return output
function M.command(args, callback, cwd)
    cwd = cwd or vim.fn.getcwd()

    local stdout_results = {}
    local stderr_results = {}

    local job = Job:new({
        command = "git",
        args = args,
        cwd = cwd,
        on_stdout = function(_, line)
            table.insert(stdout_results, line)
        end,
        on_stderr = function(_, line)
            table.insert(stderr_results, line)
        end,
    })

    local sync = not callback

    if sync then
        job:sync(30000) -- Increased timeout to 30 seconds for slow git operations
        if job.code ~= 0 then
            vim.notify("Git error: " .. table.concat(stderr_results, "\n"), vim.log.levels.ERROR)
            return nil
        end
        return stdout_results
    else
        job:start()
        job:after_success(function()
            callback(stdout_results)
        end)
        job:after_failure(function()
            vim.notify("Git error: " .. table.concat(stderr_results, "\n"), vim.log.levels.ERROR)
            callback(nil)
        end)
    end
end

-- Check if current directory is in a git repository
function M.is_git_repo()
    local output = M.command({ "rev-parse", "--is-inside-work-tree" })
    return output and output[1] == "true"
end

-- Get git status
function M.status()
    local status = {}

    -- Get raw status
    local output = M.command({ "status", "--porcelain=v2" })
    if not output then
        return nil
    end

    -- Parse status output
    status.staged = {}
    status.unstaged = {}
    status.untracked = {}

    for _, line in ipairs(output) do
        local fields = utils.split(line, " ")
        if fields[1] == "?" then
            -- Untracked file
            table.insert(status.untracked, {
                path = fields[2],
                status = "untracked",
            })
        elseif fields[1] == "1" or fields[1] == "2" then
            local entry = {
                path = fields[9],
                status = fields[2],
            }

            if fields[2]:sub(1, 1) ~= "." then
                table.insert(status.staged, entry)
            end

            if fields[2]:sub(2, 2) ~= "." then
                table.insert(status.unstaged, entry)
            end
        end
    end

    -- Get branch info
    local branch_output = M.command({ "branch", "--show-current" })
    status.branch = branch_output and branch_output[1] or "HEAD detached"

    return status
end

-- Stage file or directory
function M.stage(path)
    return M.command({ "add", path })
end

-- Unstage file or directory
function M.unstage(path)
    return M.command({ "restore", "--staged", path })
end

-- Commit changes
function M.commit(msg)
    return M.command({ "commit", "-m", msg })
end

-- Push to remote
function M.push(remote, branch)
    remote = remote or "origin"
    local args = { "push" }

    if branch then
        table.insert(args, remote)
        table.insert(args, branch)
    end

    return M.command(args)
end

-- Pull from remote
function M.pull(remote, branch)
    remote = remote or "origin"
    local args = { "pull" }

    if branch then
        table.insert(args, remote)
        table.insert(args, branch)
    end

    return M.command(args)
end

-- Get commit log
function M.log(count)
    count = count or 10
    return M.command({ "log", "-n", tostring(count), "--pretty=format:%h|%an|%ar|%s" })
end

-- Get branches
function M.branches()
    local output = M.command({ "branch" })
    local branches = {}

    for _, line in ipairs(output) do
        local current = line:sub(1, 1) == "*"
        local name = current and line:sub(3) or line:sub(3)

        table.insert(branches, {
            name = name,
            current = current,
        })
    end

    return branches
end

-- Checkout branch
function M.checkout(branch)
    return M.command({ "checkout", branch })
end

-- Create new branch
function M.create_branch(name)
    return M.command({ "checkout", "-b", name })
end

-- Delete branch
function M.delete_branch(name)
    return M.command({ "branch", "-d", name })
end

-- Get file diff
function M.diff(file, staged)
    local args = { "diff" }

    if staged then
        table.insert(args, "--staged")
    end

    if file then
        table.insert(args, file)
    end

    return M.command(args)
end

return M
