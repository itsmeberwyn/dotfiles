# devpanel

A floating-window control panel for whatever dev servers you define, plus the shell script it drives.
Start, stop, restart, and kill ports for every service without leaving Neovim.
The services live in `~/.devrc`; neither the script nor the plugin hardcodes one.

```
╭─ Dev Panel ───────────────────────────────────╮
│  ● web-api   8000  up        1137             │
│  ● web-app   3000  up        1092             │
│  ● jobs-api  8001  up        25235            │
│  ◐ jobs-app  3001  booting                    │
│  ✗ mailer    8002  dead                       │
│  ○ libs      -     down                       │
╰────────────────────────────────────── ? help ─╯
```

## Layout

Lives in the dotfiles repo at `~/.config/nvim/devpanel`, so it is versioned with the rest of the
Neovim config.

```
devpanel/
├── bin/dev                 the shell script — works standalone, no Neovim needed
├── lua/devpanel/
│   ├── init.lua            setup(), :Dev command, toggle keymap
│   ├── config.lua          defaults
│   ├── service.lua         the only module that shells out; all async
│   ├── ui.lua              float window, rendering, refresh timer, panel state
│   ├── preview.lua         the log snapshot pane
│   └── keymaps.lua         buffer-local keys
└── README.md
```

Three layers, each ignorant of the one above it:

| Layer | Knows about |
| --- | --- |
| `~/.devrc` | your services — names, ports, directories, commands |
| `bin/dev` | tmux and ports. Nothing about *your* services |
| `lua/devpanel` | rendering and keys. Nothing about services or tmux |

Nothing in the repo hardcodes a port or a path. Kill Neovim and every server keeps running.

## Install

Define your services first — `dev init` writes a commented starter file to `~/.devrc`:

```bash
~/.config/nvim/devpanel/bin/dev init
$EDITOR ~/.devrc
```

`bin/dev` alone is useful — alias it and you have the whole CLI:

```bash
alias dev=~/.config/nvim/devpanel/bin/dev   # in ~/.bashrc
```

For the panel, with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  dir = vim.fs.joinpath(vim.fn.stdpath("config"), "devpanel"),
  name = "devpanel",
  keys = { { "<leader>p", desc = "Dev panel" } },
  cmd = "Dev",
  opts = {},
}
```

Requires Neovim 0.10+ (`vim.system`, `vim.ui.open`). No plugin dependencies.

## Keys

`<leader>p` toggles the panel. Everything else is buffer-local — the keys exist only inside the
panel and vanish when it closes, so nothing in your config is shadowed. `<C-h/j/k/l>` and `<C-\>`
are deliberately left alone so tmux-navigator and windex keep working while the panel is focused.

| Key | Action |
| --- | --- |
| `s` `x` `r` | start / stop / restart the service under the cursor |
| `K` | kill whatever holds the port (SIGKILL — capital on purpose) |
| `as` `ax` `ar` `aK` | same, for **a**ll services |
| `V` then `s`/`x`/`r`/`K` | act on a visual selection — any subset of rows |
| `<Tab>` | toggle the log preview — follows the cursor from service to service |
| `<CR>` | jump to the service's tmux window to read logs |
| `b` | open `http://localhost:<port>` in the browser |
| `y` | yank that URL |
| `o` | `:tcd` to the service directory (tab-local) |
| `?` | toggle the help footer |
| `q` `<Esc>` | close |

Bulk actions are two keystrokes rather than shifted single keys, so "stop everything" is never one
slipped finger away.

## Logs

`<Tab>` opens a preview pane under the panel showing the tail of the selected service's tmux
output. Move the cursor and the preview follows; it also repaints on the panel's refresh tick.
`<CR>` still hands you to the real tmux window when you want scrollback, search, and copy mode.

The preview is a **snapshot, not a stream** — each repaint runs `tmux capture-pane` and replaces
the buffer. Measured against a running dev server:

```
tmux capture-pane, 200 lines   < 10 ms,  ~1 KB
round trip from Neovim          4.2 ms   (async — never blocks the editor)
```

At the 2s refresh tick that is two short-lived subprocesses every two seconds, and **nothing at all
between ticks**. Streaming the same logs through a `:terminal` would make Neovim's terminal
emulator parse every byte the server writes and redraw on each chunk — invisible while a server
idles, but a real cost during a webpack compile burst, multiplied by every terminal left open, plus
scrollback held per buffer. Sampling avoids all of it and costs nothing while you are not looking.

Tune with `preview = { height = 15, width = 0.8, lines = 200 }` — `width` is a fraction of the
screen when it is `<= 1`, otherwise a column count. The preview is deliberately wider than the
panel, because log lines are long.

### Logs outlive the service

Stopping or restarting a service kills its tmux window and would take the output with it, so
`stop`, `restart`, and `kill` dump the pane to `$DEV_LOG_DIR/<service>.log`
(`~/.cache/dev-logs` by default) first, ending with a `── <name> stopped <timestamp> ──` marker.
`dev tail` and the preview fall back to that file whenever there is no live window — so you can
look at *why* something died after the fact, not only while it is still up.

A service that crashes on its own keeps its tmux window (the shell outlives the command), so its
output is still live in tmux and needs no fallback.

## `:Dev`

`:Dev` with no arguments toggles the panel. With arguments it runs the script and reports back,
with completion for both the action and the target:

```vim
:Dev restart api      " every service whose name ends in -api
:Dev stop web-app
:Dev status
```

## The script

Works on its own, in any shell:

```bash
dev                # status table: port, state, pid
dev start web      # web-api + web-app
dev restart api    # every *-api service
dev stop all
dev kill jobs-app  # just free its port
dev logs web-api   # jump to its tmux window
dev tail web-api   # last 200 lines — live pane, or the saved log if it is down
dev path web-app   # print its directory (used by the panel's `o`)
dev init           # write a starter ~/.devrc
```

Targets: `all`, an exact name, a **group** (the part before the dash), or a **kind** (the part
after it) — for the services above, `web`, `jobs`, `api`, `app`.
Groups and kinds are derived from service names, not hardcoded — name a service `<group>-<kind>`
and both targets work immediately.

## `~/.devrc`

The only file that knows what you run. Plain bash, sourced by the script; `$DEVRC` overrides the
location (handy for a per-project set).

```bash
DEV_ROOT=~/code/project       # base for relative dirs below   (default: $HOME)
DEV_SESSION=dev               # tmux session for the windows   (default: dev)
DEV_CMD="pnpm dev"            # used when an entry names none  (default: pnpm dev)
DEV_LOG_DIR=~/.cache/dev-logs # where output is kept after a service dies

# "name port dir [command]"
SERVICES=(
  "web-api  8000 services/api"
  "web-app  3000 services/app"
  "libs     -    . pnpm watch:libs"
  "worker   8002 ~/other/worker go run ."
)
```

- **name** — `<group>-<kind>` earns the free group and kind targets described above.
- **port** — watched for up/down. Use `-` for a watcher that listens on nothing (a `tsc --watch`,
  a queue consumer); those report up whenever their tmux window is alive.
- **dir** — absolute, `~/…`, or relative to `$DEV_ROOT`.
- **command** — everything after the dir. Defaults to `$DEV_CMD`.

The panel picks up new services on its next refresh. Nothing else to register.

See `devrc.example` for the annotated version.

## How it works

- **Process lifetime is tmux.** Each service runs in its own window of the `$DEV_SESSION` session,
  so logs stay live and attachable. No daemon, no PID files.
- **Four states, read from reality.** Nothing here can get out of sync with what is running —
  a server you started by hand still shows as up.

  | | State | Means |
  | --- | --- | --- |
  | `●` | `up` | something is listening on the port |
  | `◐` | `booting` | its window is running something, nothing bound yet — normal while a slow build compiles |
  | `✗` | `dead` | its window is there but idle at a prompt: it crashed, or you stopped it by hand |
  | `○` | `down` | no window at all |

  `booting` and `dead` are told apart by whether the window's shell has a child process, so a
  crash never masquerades as a slow compile.

- **`start` replaces, never duplicates.** tmux will happily create a second window with the same
  name, after which every `-t session:name` lookup silently picks one of them. So `start` on a
  `dead` service saves its log, clears the old window, and opens a fresh one. On an `up` or
  `booting` service it refuses and tells you to use `restart` — a compile in progress is not
  something to throw away by accident.
- **`stop` is two-stage** — kill the tmux window, then TERM/KILL anything still on the port.
  `node --watch` leaves orphans that outlive the shell.
- **Everything is async.** Actions go through `vim.system`, so a two-second `stop` never blocks the
  editor.
- **Optimistic rows, only where needed.** Starting needs no guess — the row goes `booting` the
  moment the window exists. Stopping does: the window is gone instantly while the port lingers a
  second or two, so those rows show `stopping…` until the state agrees, or 60s passes.
- **The panel polls every 2s** while open, and stops the timer when it closes.

## Configuration

```lua
require("devpanel").setup({
  script = vim.fs.joinpath(vim.fn.stdpath("config"), "devpanel", "bin", "dev"),
  refresh_ms = 2000,
  pending_ms = 60000,
  preview = { height = 15, width = 0.8, lines = 200 },
  toggle_key = "<leader>p",   -- set to false to map it yourself
  window = { width = 52, border = "rounded", title = " Dev Panel " },
})
```

## Troubleshooting

- **`no services defined`** — run `dev init`, or point `$DEVRC` at your file.
- **Everything shows `down`** — check the script path in `setup()`, and that `bin/dev` is executable.
- **`<CR>` does nothing** — you are outside tmux; it opens a terminal tab running `tmux attach` instead.
- **`command not found` in a tmux window** — the window runs your login shell; the command in
  `~/.devrc` has to be on the `PATH` that `~/.bashrc` sets up.
- **A service starts and dies immediately** — press `<CR>` to read the failure in its tmux window.

## Not included, on purpose

Live log *streaming* inside Neovim (see Logs above — sampling is cheaper and tmux does tailing
better), a JSON output mode (four whitespace
columns need no schema), health checks beyond the port, and start/stop notifications (the panel is
already open and refreshing).
