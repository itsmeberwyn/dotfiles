return {
	dir = vim.fs.joinpath(vim.fn.stdpath("config"), "devpanel"),
	name = "devpanel",
	keys = { { "<leader>p", desc = "Dev panel" } },
	cmd = "Dev",
	opts = {},
}
