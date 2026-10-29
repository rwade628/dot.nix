-- Custom vim options
vim.opt.scrolloff = 0
vim.opt.sidescrolloff = 0

-- WSLg's compositor has no primary selection, so the default wl-clipboard
-- provider errors whenever the * register is read. Point * at the regular
-- clipboard instead.
if vim.fn.has("wsl") == 1 then
	vim.g.clipboard = {
		name = "wl-clipboard (no primary)",
		copy = { ["+"] = { "wl-copy", "--type", "text/plain" }, ["*"] = { "wl-copy", "--type", "text/plain" } },
		paste = { ["+"] = { "wl-paste", "--no-newline", "--type", "text" }, ["*"] = { "wl-paste", "--no-newline", "--type", "text" } },
		cache_enabled = 1,
	}
end
