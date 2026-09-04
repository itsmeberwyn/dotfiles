-- Buffer-local maps. They exist only inside the panel, so plain letters are safe
-- and <C-h/j/k/l> / <C-\> stay with tmux-navigator and windex.
local service = require("devpanel.service")

local M = {}

-- action, verb shown while we wait, state we expect afterwards.
-- start/restart need no verb: the script reports `booting` for real once the window is up.
local ACTIONS = {
  s = { "start" },
  x = { "stop", "stopping…", false },
  r = { "restart" },
  K = { "kill", "killing…", false },
}

local function act(ui, action, visual)
  local names = ui.targets(visual)
  if #names == 0 then return end
  local spec = ACTIONS[action]
  if spec[2] then ui.mark_pending(names, spec[2], spec[3]) end
  service.act(spec[1], names, function() ui.refresh() end)
  ui.refresh()
end

local function act_all(ui, action)
  local spec = ACTIONS[action]
  local names = vim.tbl_map(function(row) return row.name end, ui.state.rows)
  if spec[2] then ui.mark_pending(names, spec[2], spec[3]) end
  service.act(spec[1], { "all" }, function() ui.refresh() end)
  ui.refresh()
end

local function logs(ui)
  local row = ui.row_under_cursor()
  if not row then return end
  if vim.env.TMUX then
    service.run({ "logs", row.name })
  else
    -- Outside tmux `logs` needs a terminal to attach in. The script picks the session,
    -- so the name never has to be duplicated here.
    ui.close()
    vim.cmd.tabnew()
    vim.cmd.terminal(require("devpanel.config").options.script .. " logs " .. row.name)
  end
end

function M.attach(buf)
  local ui = require("devpanel.ui")
  local function map(mode, lhs, fn, desc)
    vim.keymap.set(mode, lhs, fn, { buffer = buf, nowait = true, silent = true, desc = desc })
  end

  for key, spec in pairs(ACTIONS) do
    map("n", key, function() act(ui, key, false) end, "devpanel: " .. spec[1])
    map("x", key, function() act(ui, key, true) end, "devpanel: " .. spec[1] .. " (selection)")
    map("n", "a" .. key, function() act_all(ui, key) end, "devpanel: " .. spec[1] .. " all")
  end

  map("n", "<Tab>", function() require("devpanel.preview").toggle(ui) end, "devpanel: toggle log preview")
  map("n", "<CR>", function() logs(ui) end, "devpanel: logs in tmux")

  map("n", "b", function()
    local row = ui.row_under_cursor()
    if not row or row.port == "-" then return end
    vim.ui.open("http://localhost:" .. row.port)
  end, "devpanel: open in browser")

  map("n", "y", function()
    local row = ui.row_under_cursor()
    if not row or row.port == "-" then return end
    local url = "http://localhost:" .. row.port
    vim.fn.setreg("+", url)
    vim.notify(url .. " yanked")
  end, "devpanel: yank url")

  map("n", "o", function()
    local row = ui.row_under_cursor()
    if not row then return end
    service.path(row.name, function(dir)
      if not dir or dir == "" then return end
      ui.close()
      vim.cmd.tcd(dir)
      vim.notify("cwd → " .. dir)
    end)
  end, "devpanel: cd to service dir")

  map("n", "?", function()
    ui.state.help = not ui.state.help
    ui.refresh()
  end, "devpanel: toggle help")

  map("n", "q", function() ui.close() end, "devpanel: close")
  map("n", "<Esc>", function() ui.close() end, "devpanel: close")
end

return M
