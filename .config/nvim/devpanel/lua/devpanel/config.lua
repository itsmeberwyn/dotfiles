-- Defaults. Override via require("devpanel").setup({...}).
local M = {}

M.defaults = {
  -- Path to the `dev` shell script. Everything the plugin knows comes from it.
  script = vim.fs.joinpath(vim.fn.stdpath("config"), "devpanel", "bin", "dev"),
  -- How often the panel re-reads status while it is open (ms).
  refresh_ms = 2000,
  -- How long a row keeps showing "starting…" before giving up on the guess (ms).
  pending_ms = 60000,
  toggle_key = "<leader>p",
  -- Log preview: a snapshot of the tmux pane, not a live stream.
  preview = {
    height = 15,
    -- Wider than the panel: log lines are long. <= 1 is a fraction of the screen.
    width = 0.8,
    lines = 200,   -- how much scrollback to pull per snapshot
  },
  window = {
    width = 52,
    border = "rounded",
    title = " Dev Panel ",
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
  return M.options
end

return M
