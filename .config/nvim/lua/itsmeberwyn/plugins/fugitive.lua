-- Note: you must first go inside the fugitive UI, :G or <leader>gs
-- s <- to add untracked files to staged files
-- = <- to show inline diff
-- dv <- to show split diff
-- dq <- to exit split diff
-- u <- to unstage the file
-- X <- to delete the changes to the file
-- cc <- to go to the commit page
-- Branches
-- :G checkout -b <branch-name>
return {
	"tpope/vim-fugitive",
	config = function()
		vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
		vim.keymap.set("n", "go", "<cmd>diffget //2<CR>")
		vim.keymap.set("n", "gn", "<cmd>diffget //3<CR>")
	end,
}
