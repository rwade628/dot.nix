return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            auto_close = true,
          },
        },
      },
    },
    keys = {
      { "\\", "<leader>fe", desc = "Explorer Snacks (root dir)", remap = true },
    },
  },
}
