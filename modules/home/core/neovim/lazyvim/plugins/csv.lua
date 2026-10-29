return {
	-- aligned table view for .csv/.tsv; edits the real file underneath
	{
		"hat0uma/csvview.nvim",
		ft = { "csv", "tsv" },
		cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
		opts = {
			view = { display_mode = "border" },
			keymaps = {
				textobject_field_inner = { "if", mode = { "o", "x" } },
				textobject_field_outer = { "af", mode = { "o", "x" } },
				jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
				jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
			},
		},
		config = function(_, opts)
			local csvview = require("csvview")
			csvview.setup(opts)
			local function enable(buf)
				if not csvview.is_enabled(buf) then
					csvview.enable(buf)
				end
			end
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "csv", "tsv" },
				callback = function(ev)
					enable(ev.buf)
				end,
			})
			-- the buffer whose FileType triggered the lazy load
			if vim.tbl_contains({ "csv", "tsv" }, vim.bo.filetype) then
				enable(vim.api.nvim_get_current_buf())
			end
		end,
	},
}
