return {
  "nvim-tree/nvim-tree.lua",
  dependencies = "nvim-tree/nvim-web-devicons",
  enabled = false,
  config = function()
		local nvimtree = require("nvim-tree")

		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwplugin = 1

		nvimtree.setup({
			view = {
				width = 35,
				relativenumber = true,
			},
			renderer = {
				indent_markers = {
					enable = true,
				},
				icons = {
					glyphs = {
						folder = {
							arrow_closed = "",
							arrow_open = "",
						},
					},
				},
			},
			actions = {
				open_file = {
					window_picker = {
						enable = false,
					},
				},
			},
			filters = {
				custom = { ".ds_store" },
			},
			git = {
				ignore = false,
			},
    })

		local keymap = vim.keymap

		keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "toggle file explorer" })
		keymap.set("n", "<leader>w", "<cmd>NvimTreeFocus<cr>", { desc = "focus on tab file" })
		-- keymap.set("n", "<leader>ef", "<cmd>NvimTreeFindFileToggle<cr>", { desc = "toggle file explorer on current file" })
  end
}
