return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")
		local mason_tool_installer = require("mason-tool-installer")

		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		mason_lspconfig.setup({
			ensure_installed = {
				"ts_ls",
				"html",
				"cssls",
				"lua_ls",
				-- "emmet_ls",
				-- "emmet_language_server",
				-- "pyright",
				-- "golangci_lint_ls",
				-- "gopls",
				-- "intelephense",
			},
			-- Off on purpose: with this on, opening an unfamiliar filetype downloads and runs a
			-- language server binary without asking. The list above still installs on startup;
			-- anything else is a deliberate `:Mason` install.
			automatic_installation = false,
		})

		mason_tool_installer.setup({
			ensure_installed = {
				"prettier", -- prettier formatter
				"stylua", -- lua formatter
				"eslint_d", -- js linter
        "js-debug-adapter",
        "netcoredbg",
        "ruff",
			},
		})
	end,
}
