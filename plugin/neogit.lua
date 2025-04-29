if vim.fn.has("nvim-0.7") == 0 then
	vim.api.nvim_err_writeln("NeoGit requires at least Neovim 0.7")
	return
end

