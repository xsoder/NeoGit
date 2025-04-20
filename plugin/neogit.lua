if vim.fn.has("nvim-0.7") == 0 then
	vim.api.nvim_err_writeln("NeoGit requires at least Neovim 0.7")
	return
end

local has_neogit, neogit = pcall(require, "neogit")

if not has_neogit then
	vim.notify("Could not load NeoGit", vim.log.levels.ERROR)
	return
end

neogit.setup({})
