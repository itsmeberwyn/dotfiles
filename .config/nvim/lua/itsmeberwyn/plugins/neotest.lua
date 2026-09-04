return {
	"nvim-neotest/neotest",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
		"marilari88/neotest-vitest",
	},
	config = function()
		local status_ok, neotest = pcall(require, "neotest")
		if not status_ok then
			return
		end

		-- Neotest reads test files from disk, and vim.filetype.match() cannot resolve a bare
		-- ".ts" path without a buffer (the extension is ambiguous with Qt translation XML), so
		-- discovery dies with "expected string, got nil" on every .ts test. Pin the extension.
		vim.filetype.add({ extension = { ts = "typescript" } })

		local vitest = require("neotest-vitest")

		neotest.setup({
			summary = {
				open = "botright vsplit | vertical resize 80",
			},
			-- The defaults are Nerd Font private-use glyphs, which paint as blank in a font
			-- that lacks them — the run works but looks like nothing happened.
			icons = {
				passed = "✓",
				failed = "✗",
				running = "●",
				skipped = "○",
				unknown = "?",
				running_animated = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
			},
			-- Up-front discovery walks every file under the project root, and when nvim is
			-- started outside a project that root becomes the cwd — from ~/workstation that is
			-- 100k+ positions and the run queues behind the scan. Discover on demand instead:
			-- files you open or run get parsed, nothing else.
			discovery = {
				enabled = false,
				concurrent = 0,
			},

			-- Failures become buffer diagnostics, so ]d, :Trouble and the quickfix list all
			-- reach the message without opening a float at all.
			diagnostic = {
				enabled = true,
				severity = vim.diagnostic.severity.ERROR,
			},

			-- Signs alone are easy to miss; virtual text puts the result on the test line.
			status = {
				enabled = true,
				signs = true,
				virtual_text = true,
			},
			adapters = {
				vitest({
					vitestCommand = "pnpm exec vitest",
					-- Run from the package that owns the test, not the monorepo root:
					-- rooted at the repo, a single-file run fires the whole turbo suite.
					cwd = function(file)
						return vim.fs.root(file, {
							"vitest.config.mts",
							"vitest.config.ts",
							"vitest.config.js",
						}) or vim.fs.root(file, "package.json")
					end,
					filter_dir = function(name)
						return name ~= "node_modules" and name ~= ".next" and name ~= "dist"
					end,
				}),
			},
		})
	end,
	keys = {
		{ "<leader>t", "", desc = "+test" },
		{
			"<leader>tt",
			function()
				require("neotest").run.run(vim.fn.expand("%"))
			end,
			desc = "Run File (Neotest)",
		},
		{
			"<leader>tT",
			function()
				require("neotest").run.run(vim.uv.cwd())
			end,
			desc = "Run All Test Files (Neotest)",
		},
		{
			"<leader>tr",
			function()
				require("neotest").run.run()
			end,
			desc = "Run Nearest (Neotest)",
		},
		{
			"<leader>tl",
			function()
				require("neotest").run.run_last()
			end,
			desc = "Run Last (Neotest)",
		},
		{
			"<leader>ts",
			function()
				require("neotest").summary.toggle()
			end,
			desc = "Toggle Summary (Neotest)",
		},
		{
			"<leader>to",
			function()
				-- enter = true focuses the float so the failure text can be yanked;
				-- the one that pops up automatically on failure is not focusable.
				require("neotest").output.open({ enter = true, auto_close = true })
			end,
			desc = "Show Output (Neotest)",
		},
		{
			"<leader>tO",
			function()
				require("neotest").output_panel.toggle()
			end,
			desc = "Toggle Output Panel (Neotest)",
		},
		{
			"<leader>tS",
			function()
				require("neotest").run.stop()
			end,
			desc = "Stop (Neotest)",
		},
		{
			"<leader>tw",
			function()
				require("neotest").watch.toggle(vim.fn.expand("%"))
			end,
			desc = "Toggle Watch (Neotest)",
		},
	},
}
