return {
	"ThePrimeagen/harpoon",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local keymap = vim.keymap

		keymap.set("n", "<leader><leader>", ":lua require('harpoon.ui').toggle_quick_menu()<CR>", {})
		keymap.set("n", "<leader>a", ":lua require('harpoon.mark').add_file()<CR>", {})
		keymap.set("n", "<A-1>", ":lua require('harpoon.ui').nav_file(1)<CR>", {})
		keymap.set("n", "<A-2>", ":lua require('harpoon.ui').nav_file(2)<CR>", {})
		keymap.set("n", "<A-3>", ":lua require('harpoon.ui').nav_file(3)<CR>", {})
		keymap.set("n", "<A-4>", ":lua require('harpoon.ui').nav_file(4)<CR>", {})
		keymap.set("n", "<A-n>", ":lua require('harpoon.ui').nav_next()<CR>", {})
		keymap.set("n", "<A-p>", ":lua require('harpoon.ui').nav_prev()<CR>", {})
		keymap.set("n", "<leader>c", ":lua require('harpoon.mark').clear_all()<CR>", {})
	end,
}
