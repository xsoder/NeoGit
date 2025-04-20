-- lua/neogit/config.lua
local M = {}

local default_config = {
    disable_signs = false,
    disable_hint = false,
    disable_context_highlighting = false,
    status = {
        recent_commit_count = 10,
    },
    auto_refresh = true,
    integrations = {
        telescope = true,
        diffview = false,
    },
    sections = {
        untracked = {
            folded = false,
        },
        unstaged = {
            folded = false,
        },
        staged = {
            folded = false,
        },
        stashes = {
            folded = true,
        },
        unpulled = {
            folded = true,
        },
        unmerged = {
            folded = false,
        },
        recent = {
            folded = true,
        },
    },
}

M.values = vim.deepcopy(default_config)

function M.setup(user_config)
    M.values = vim.tbl_deep_extend("force", default_config, user_config or {})
end

return M
