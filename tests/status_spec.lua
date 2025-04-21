package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

-- Mock plenary.job if running outside Neovim
package.loaded["plenary.job"] = package.loaded["plenary.job"]
	or {
		new = function()
			return setmetatable({ start = function() end }, {
				__index = function()
					return function() end
				end,
			})
		end,
	}

-- Minimal vim mock for testing outside Neovim
_G.vim = _G.vim or {}
vim.api = vim.api or {}
vim.api.nvim_buf_is_valid = vim.api.nvim_buf_is_valid or function()
	return true
end
vim.api.nvim_win_is_valid = vim.api.nvim_win_is_valid or function()
	return true
end
vim.api.nvim_buf_set_lines = vim.api.nvim_buf_set_lines or function() end
vim.api.nvim_buf_set_option = vim.api.nvim_buf_set_option or function() end
vim.api.nvim_buf_add_highlight = vim.api.nvim_buf_add_highlight or function() end
vim.api.nvim_set_current_win = vim.api.nvim_set_current_win or function() end
vim.api.nvim_set_hl = vim.api.nvim_set_hl or function() end
vim.api.nvim_create_autocmd = vim.api.nvim_create_autocmd or function() end
vim.fn = vim.fn or {}
vim.fn.fnamemodify = vim.fn.fnamemodify or function(path, _)
	return path
end
vim.fn.getcwd = vim.fn.getcwd or function()
	return "/mock/project"
end
vim.notify = vim.notify or function() end
vim.deepcopy = vim.deepcopy
	or function(orig)
		local orig_type = type(orig)
		local copy
		if orig_type == "table" then
			copy = {}
			for orig_key, orig_value in next, orig, nil do
				copy[vim.deepcopy(orig_key)] = vim.deepcopy(orig_value)
			end
			setmetatable(copy, getmetatable(orig))
		else
			copy = orig
		end
		return copy
	end

local stub = require("luassert.stub")
local neogit_status = require("neogit.status")
local ui_buffers = require("neogit.ui.buffers")
local git = require("neogit.git")

-- Helper to simulate buffer and window
local function mock_vim()
	_G.vim = _G.vim or {}
	vim.api = vim.api or {}
	vim.api.nvim_buf_is_valid = function()
		return true
	end
	vim.api.nvim_win_is_valid = function()
		return true
	end
	vim.api.nvim_buf_set_lines = function() end
	vim.api.nvim_buf_set_option = function() end
	vim.api.nvim_buf_add_highlight = function() end
	vim.api.nvim_set_current_win = function() end
end

mock_vim()

describe("Neogit UI", function()
	it("applies correct highlight groups to project and branch lines", function()
		local highlights = {}
		vim.api.nvim_buf_add_highlight = function(_, _, hl_group, line, _, _)
			highlights[line] = hl_group
		end
		-- Simulate status
		stub(git, "status").returns({
			branch = "main",
			staged = {},
			unstaged = {},
			untracked = {},
		})
		-- Simulate valid buffer
		local neogit_status_mod = require("neogit.status")
		neogit_status_mod.__private_state.buffer = 1
		neogit_status_mod.update_status_content()
		assert.are.same("NeoGitProject", highlights[0])
		assert.are.same("NeoGitBranch", highlights[1])
	end)

	it("shows branch selection menu on push", function()
		local selected_branch
		vim.ui = vim.ui or {}
		vim.ui.select = function(branches, opts, cb)
			cb("feature-branch")
		end
		stub(git, "branches").returns({
			{ name = "main" },
			{ name = "feature-branch" },
		})
		local pushed_branch
		git.push = function(_, branch)
			pushed_branch = branch
		end
		-- Simulate valid buffer
		local neogit_status_mod = require("neogit.status")
		neogit_status_mod.__private_state.buffer = 1
		neogit_status_mod._push_selected_branch()
		assert.are.same("feature-branch", pushed_branch)
	end)
end)
