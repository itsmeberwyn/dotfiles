-- The only module that talks to the shell. Everything is async.
local config = require("devpanel.config")

local M = {}

---Run `dev <args...>`; cb(lines, result) on the main loop.
function M.run(args, cb)
  local cmd = { config.options.script }
  vim.list_extend(cmd, args)
  vim.system(cmd, { text = true }, function(res)
    local out = (res.stdout or "") .. (res.stderr or "")
    vim.schedule(function()
      if res.code ~= 0 and out ~= "" and not vim.tbl_contains({ "path", "port", "tail" }, args[1]) then
        vim.notify("dev " .. table.concat(args, " ") .. ": " .. vim.trim(out), vim.log.levels.WARN)
      end
      if cb then cb(vim.split(out, "\n", { trimempty = true }), res) end
    end)
  end)
end

---cb(rows) where row = { name, port, up, pid }. Header lines never match, so they drop out.
function M.status(cb)
  M.run({ "status" }, function(lines)
    local rows = {}
    for _, line in ipairs(lines) do
      local name, port, state, pid = line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)$")
      if name and name ~= "SERVICE" then
        rows[#rows + 1] = {
          name = name,
          port = port,
          state = state,               -- up | booting | down, straight from the script
          up = state == "up",
          pid = pid ~= "-" and pid or nil,
        }
      end
    end
    cb(rows)
  end)
end

---Fire an action at one or more services, then call cb once all have finished.
function M.act(action, names, cb)
  local left = #names
  if left == 0 then return cb and cb() end
  for _, name in ipairs(names) do
    M.run({ action, name }, function()
      left = left - 1
      if left == 0 and cb then cb() end
    end)
  end
end

function M.path(name, cb)
  M.run({ "path", name }, function(lines) cb(lines[1]) end)
end

return M
