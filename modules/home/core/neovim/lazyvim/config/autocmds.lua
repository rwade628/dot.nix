-- Treat hujson (https://github.com/tailscale/hujson) as jsonc so it picks up
-- jsonc's treesitter parser (json grammar) and LSP (jsonls) via LazyVim's json extra
vim.filetype.add({
  extension = {
    hujson = "jsonc",
  },
})
