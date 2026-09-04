-- Floating window: render, highlight, refresh timer. Owns all panel state.
local config = require("devpanel.config")
local service = require("devpanel.service")

local M = {}
local ns = vim.api.nvim_create_namespace("devpanel")

M.state = {
  buf = nil,
  win = nil,
  timer = nil,
  rows = {},      -- last status read
  pending = {},   -- name -> { verb, want, at } while we wait for the port to flip
  help = false,
}

local HELP = {
  "s start   x stop   r restart   K kill port",
  "as/ax/ar all      V + s/x/r for a selection",
  "<Tab> peek logs   <CR> open in tmux",
  "b browser   y yank url   o cd",
  "? help    q close",
}

function M.is_open()
  return M.state.win ~= nil and vim.api.nvim_win_is_valid(M.state.win)
end

---A row shows its pending verb until the port agrees, or pending_ms elapses.
---Where the panel sits when it is on its own. `lift` makes room for the preview below.
function M.geom(height, lift)
  local width = config.options.window.width
  return {
    relative = "editor",
    width = width,
    height = height,
    row = lift or math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
  }
end

---Put the panel back where it belongs after the preview closes.
function M.recenter()
  if not M.is_open() or require("devpanel.preview").is_open() then return end
  vim.api.nvim_win_set_config(M.state.win, M.geom(vim.api.nvim_buf_line_count(M.state.buf)))
end

-- Icon and highlight per real state. `booting` is a live tmux window whose port has not come
-- up yet — the normal state while a slow build compiles, and not a failure.
local STATE = {
  up      = { "●", "DiagnosticOk" },
  booting = { "◐", "DiagnosticWarn" },
  dead    = { "✗", "DiagnosticError" },  -- window still there, nothing running in it
  down    = { "○", "Comment" },          -- not running, nothing left behind
}

local function pending_label(name, up)
  local p = M.state.pending[name]
  if not p then return nil end
  local expired = (vim.uv.now() - p.at) > config.options.pending_ms
  if up == p.want or expired then
    M.state.pending[name] = nil
    return nil
  end
  return p.verb
end

function M.mark_pending(names, verb, want)
  for _, name in ipairs(names) do
    M.state.pending[name] = { verb = verb, want = want, at = vim.uv.now() }
  end
end

local function render()
  if not M.is_open() then return end
  local lines, marks = {}, {}

  for i, row in ipairs(M.state.rows) do
    local look = STATE[row.state] or STATE.down
    local label = pending_label(row.name, row.up)
    local icon = label and "◐" or look[1]
    lines[i] = string.format("  %s %-9s %-5s %-9s %s", icon, row.name, row.port,
      label or row.state, row.pid or "")
    marks[i] = label and "DiagnosticWarn" or look[2]
  end

  if #lines == 0 then
    lines = { "  no services — is " .. config.options.script .. " there?" }
  end

  if M.state.help then
    lines[#lines + 1] = ""
    for _, h in ipairs(HELP) do lines[#lines + 1] = "  " .. h end
  end

  vim.bo[M.state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)
  vim.bo[M.state.buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(M.state.buf, ns, 0, -1)
  for i, hl in pairs(marks) do
    vim.api.nvim_buf_set_extmark(M.state.buf, ns, i - 1, 0, { end_col = #lines[i], hl_group = hl })
  end
  for i = #M.state.rows + 1, #lines do
    vim.api.nvim_buf_set_extmark(M.state.buf, ns, i - 1, 0, { end_col = #lines[i], hl_group = "Comment" })
  end

  -- Re-apply the whole geometry, not just the height: the preview lifts the panel and
  -- closing it has to put the row back too.
  if not require("devpanel.preview").is_open() then
    vim.api.nvim_win_set_config(M.state.win, M.geom(#lines))
  end
end

function M.refresh()
  service.status(function(rows)
    M.state.rows = rows
    render()
    require("devpanel.preview").update(M, true)
  end)
end

---Service names on the cursor line, or under a visual selection.
function M.targets(visual)
  local first, last = vim.fn.line("."), vim.fn.line(".")
  if visual then
    first, last = math.min(vim.fn.line("v"), first), math.max(vim.fn.line("v"), last)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  end
  local names = {}
  for i = first, last do
    local row = M.state.rows[i]
    if row then names[#names + 1] = row.name end
  end
  return names
end

function M.row_under_cursor()
  return M.state.rows[vim.fn.line(".")]
end

function M.close()
  require("devpanel.preview").close()
  if M.state.timer then
    M.state.timer:stop()
    M.state.timer:close()
    M.state.timer = nil
  end
  if M.is_open() then vim.api.nvim_win_close(M.state.win, true) end
  M.state.win, M.state.buf = nil, nil
end

function M.open()
  local opts = config.options
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "devpanel"

  -- Keep the new ids local until the window exists: opening it fires BufLeave on
  -- any panel already up, and that handler resets M.state.
  local win = vim.api.nvim_open_win(buf, true, vim.tbl_extend("force", M.geom(math.max(#M.state.rows, 1)), {
    style = "minimal",
    border = opts.window.border,
    title = opts.window.title,
    title_pos = "center",
    footer = " ?  help ",
    footer_pos = "right",
  }))
  M.state.buf, M.state.win = buf, win
  vim.wo[win].cursorline = true
  vim.wo[win].winfixbuf = true

  require("devpanel.keymaps").attach(buf)

  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function() require("devpanel.preview").update(M, false) end,
  })

  vim.api.nvim_create_autocmd({ "WinClosed", "BufLeave" }, {
    buffer = buf,
    once = true,
    callback = function()
      if M.state.buf == buf then M.close() end
    end,
  })

  M.refresh()
  M.state.timer = vim.uv.new_timer()
  M.state.timer:start(opts.refresh_ms, opts.refresh_ms, vim.schedule_wrap(M.refresh))
end

function M.toggle()
  if M.is_open() then M.close() else M.open() end
end

return M
