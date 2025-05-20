return {
	"folke/persistence.nvim",
	event = "BufReadPre", -- this will only start session saving when an actual file was opened
	opts = {
		dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"), -- directory where session files are saved
		options = { "buffers", "curdir", "tabpages", "winsize" }, -- sessionoptions used for saving
		pre_save = nil, -- a function to call before saving the session
		save_empty = false, -- don't save if there are no open file buffers
	},
	keys = {
		{
			"<leader>qs",
			function()
				require("persistence").load()
			end,
			desc = "load the session for the current directory",
		},
		{
			"<leader>qS",
			function()
				require("persistence").select()
			end,
			desc = "Select Session",
		},
		{
			"<leader>ql",
			function()
				require("persistence").load({ last = true })
			end,
			desc = "load the last session",
		},
		{
			"<leader>qd",
			function()
				require("persistence").stop()
			end,
			desc = "stop Persistence => session won't be saved on exit",
		},
	},
}
