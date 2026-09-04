-- Entry point: setup, toggle, and the :Dev command.
local config = require("devpanel.config")

local M = {}

local COMMANDS = { "status", "start", "stop", "restart", "kill", "logs", "path", "port" }

function M.toggle() require("devpanel.ui").toggle() end
function M.open() require("devpanel.ui").open() end
function M.close() require("devpanel.ui").close() end

function M.setup(opts)
  config.setup(opts)

  if config.options.toggle_key then
    vim.keymap.set("n", config.options.toggle_key, M.toggle, { desc = "Dev panel" })
  end

  vim.api.nvim_create_user_command("Dev", function(args)
    if #args.fargs == 0 then return M.toggle() end
    require("devpanel.service").run(args.fargs, function(lines)
      if #lines > 0 then vim.notify(table.concat(lines, "\n")) end
      if require("devpanel.ui").is_open() then require("devpanel.ui").refresh() end
    end)
  end, {
    nargs = "*",
    desc = "Run the dev script (no args: toggle the panel)",
    complete = function(lead, line)
      local words = vim.split(vim.trim(line), "%s+")
      if #words > 2 or (#words == 2 and lead == "") then
        -- second argument: a target. Ask the script what exists; derive the group and
        -- kind targets from the names themselves, so nothing here knows your services.
        local out = vim.fn.systemlist({ config.options.script, "status" })
        local names, seen = { "all" }, {}
        for _, l in ipairs(out) do
          local name = l:match("^(%S+)%s+%S+%s+%a")
          if name and name ~= "SERVICE" then
            names[#names + 1] = name
            local group, kind = name:match("^([^-]+)"), name:match("([^-]+)$")
            for _, part in ipairs({ group, kind }) do
              if part and part ~= "" and not seen[part] then
                seen[part] = true
                names[#names + 1] = part
              end
            end
          end
        end
        return vim.tbl_filter(function(n) return n:find(lead, 1, true) == 1 end, names)
      end
      return vim.tbl_filter(function(c) return c:find(lead, 1, true) == 1 end, COMMANDS)
    end,
  })

  return M
end

return M
