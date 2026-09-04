-- Log preview: a snapshot of the service's tmux pane, sampled rather than streamed.
-- `tmux capture-pane` costs a few milliseconds, so we pay only when the selection
-- changes or the panel timer ticks — nothing runs between refreshes.
local config = require("devpanel.config")
local service = require("devpanel.service")

local M = {}
M.state = { buf = nil, win = nil, showing = nil, geom = nil }

function M.is_open()
  return M.state.win ~= nil and vim.api.nvim_win_is_valid(M.state.win)
end

---Lift the panel so panel + preview sit centered as one block; return the preview geometry.
---The preview gets its own width (logs need the room) and is centered independently.
local function place(ui)
  local opts = config.options.preview
  local panel = vim.api.nvim_win_get_config(ui.state.win)
  local width = opts.width <= 1 and math.floor(vim.o.columns * opts.width) or opts.width
  width = math.max(panel.width, math.min(width, vim.o.columns - 4))
  local height = math.max(5, math.min(opts.height, vim.o.lines - panel.height - 8))
  local top = math.max(0, math.floor((vim.o.lines - (panel.height + height + 5)) / 2))
  vim.api.nvim_win_set_config(ui.state.win, ui.geom(panel.height, top))
  return {
    relative = "editor",
    row = top + panel.height + 3,
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
  }
end

function M.close()
  if M.is_open() then vim.api.nvim_win_close(M.state.win, true) end
  M.state.win, M.state.buf, M.state.showing, M.state.geom = nil, nil, nil, nil
end

function M.open(ui)
  M.state.geom = place(ui)
  M.state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[M.state.buf].bufhidden = "wipe"
  M.state.win = vim.api.nvim_open_win(M.state.buf, false, vim.tbl_extend("force", M.state.geom, {
    style = "minimal",
    border = config.options.window.border,
    focusable = false,
    title = " logs ",
    title_pos = "left",
  }))
  vim.wo[M.state.win].wrap = false
  M.update(ui, true)
end

function M.toggle(ui)
  if M.is_open() then
    M.close()
    ui.recenter()
  else
    M.open(ui)
  end
end

---force=true refetches the current service; otherwise only a changed selection refetches,
---so holding `j` down does not spawn a snapshot per row.
function M.update(ui, force)
  if not M.is_open() then return end
  local row = ui.row_under_cursor()
  if not row then return end
  if not force and M.state.showing == row.name then return end
  M.state.showing = row.name

  service.run({ "tail", row.name, tostring(config.options.preview.lines) }, function(lines)
    if not M.is_open() or M.state.showing ~= row.name then return end
    while #lines > 0 and vim.trim(lines[#lines]) == "" do table.remove(lines) end
    if #lines == 0 then lines = { "  (no output)" } end

    vim.bo[M.state.buf].modifiable = true
    vim.api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)
    vim.bo[M.state.buf].modifiable = false
    vim.api.nvim_win_set_cursor(M.state.win, { #lines, 0 }) -- stick to the newest line
    vim.api.nvim_win_set_config(M.state.win, vim.tbl_extend("force", M.state.geom, {
      title = " logs: " .. row.name .. " ",
      title_pos = "left",
      border = config.options.window.border,
    }))
  end)
end

return M
