# Setting up devpanel

Start to finish on a new machine. Every step has a check — run it before moving on.
Roughly ten minutes, most of it deciding what goes in `~/.devrc`.

---

## 1. Requirements

| Need | Why | Debian/Ubuntu |
| --- | --- | --- |
| `tmux` | holds every service in its own window | `tmux` |
| `ss` | which port is listening | `iproute2` |
| `fuser` | frees a port on stop/kill | `psmisc` |
| `pgrep` | tells a compiling window from a dead one | `procps` |
| `awk` | parses the port and window tables | `gawk` or `mawk` |
| Neovim ≥ 0.10 | `vim.system`, `vim.ui.open`, `vim.fs.root` | — |

Check all of it at once:

```bash
for c in tmux ss fuser pgrep awk nvim; do
  printf '%-6s %s\n' "$c" "$(command -v $c || echo MISSING)"
done
nvim --version | head -1
```

The shell script needs none of Neovim — install just the first five and `dev` works on its own.

---

## 2. Get the files

devpanel lives inside the Neovim config so it is versioned with your dotfiles:

```
~/.config/nvim/devpanel/
├── bin/dev                 the shell script
├── devrc.example           annotated starter config
├── lua/devpanel/           the plugin
├── README.md
└── SETUP.md                this file
```

If you cloned dotfiles that already contain it, there is nothing to install. Otherwise copy the
folder in, then make the script executable:

```bash
chmod +x ~/.config/nvim/devpanel/bin/dev
```

**Check:** `~/.config/nvim/devpanel/bin/dev` runs and says
`no services defined in ~/.devrc (run: dev init)` — that is the right answer at this stage.

---

## 3. Put `dev` on your PATH

```bash
echo 'alias dev=~/.config/nvim/devpanel/bin/dev' >> ~/.bashrc
source ~/.bashrc
```

Prefer a real binary on `PATH`? Symlink it instead — both point at the same file, so there is
never a second copy to keep in sync:

```bash
ln -sfn ~/.config/nvim/devpanel/bin/dev ~/.local/bin/dev
```

**Check:** `dev` runs from any directory (still saying `no services defined` until step 4).

---

## 4. Describe your services

```bash
dev init          # writes ~/.devrc from devrc.example
$EDITOR ~/.devrc
```

Set the three settings at the top, then one line per service — `name port dir [command]`:

```bash
DEV_ROOT=~/root/project     # base for the relative dirs below
DEV_SESSION=dev-session-name            # tmux session that will hold the windows
DEV_CMD="pnpm dev"              # used when an entry names no command

SERVICES=(
  "api  8000 project/api"
  "app  3000 project/app"
  "libs -   . npm dev"
)
```

Two things worth getting right the first time:

- **Name them `<group>-<kind>`.** Called `web-api` and `web-app`, they give you `dev restart web`
  and `dev stop api` for free. Nothing to register — the targets come from the names.
- **Use `-` as the port** for anything that listens on nothing: a `tsc --watch`, a vitest watcher,
  a queue consumer. Those are tracked by their tmux window instead.

**Check:** `dev` prints a row per service, all `down`.

```
SERVICE   PORT  STATE    PID
api       8000  down     -
app       3000  down     -
libs      -     down     -
```

If you get `no services defined`, `dev` is not finding the file — it reads `$DEVRC`, defaulting to
`~/.devrc`.

---

## 5. Try it from the shell

```bash
dev start api      # opens a tmux window and runs the command in it
dev                     # watch it go booting → up
dev tail api       # last 200 lines of its output
dev logs api       # jump to its tmux window (Ctrl-b d to come back)
dev stop api
```

**Check:** the row reaches `up`, and `tmux list-windows -t <DEV_SESSION>` shows a window named
after the service.

A service that takes a while to bind its port sits at `booting` in the meantime — that is normal,
not a failure. See the state table in `devrc.example`.

---

## 6. Wire up the Neovim panel

Add a plugin spec — with [lazy.nvim](https://github.com/folke/lazy.nvim), a file such as
`lua/<you>/plugins/devpanel.lua`:

```lua
return {
	dir = vim.fs.joinpath(vim.fn.stdpath("config"), "devpanel"),
	name = "devpanel",
	keys = { { "<leader>p", desc = "Dev panel" } },
	cmd = "Dev",
	opts = {},
}
```

`dir` points at the folder from step 2, so nothing is fetched from the network. The `keys` entry
lazy-loads on first press; keep it and `opts.toggle_key` in agreement if you change the key.

Restart Neovim — plugin config runs once at load, so an already-open session keeps the old setup.

**Check:** `:Dev status` prints the same table as the shell.

---

## 7. First run in the panel

Press `<leader>p`:

```
╭─ Dev Panel ───────────────────────────────────╮
│  ● api       8000  up        1137             │
│  ◐ app       3000  booting                    │
│  ○ libs      -     down                       │
╰────────────────────────────────────── ? help ─╯
```

- `s` / `x` / `r` start, stop, restart the row under the cursor
- `as` / `ax` / `ar` do the same for everything
- `V` then `s`/`x`/`r` acts on a selection
- `<Tab>` opens the log preview, which follows the cursor between services
- `<CR>` jumps to the real tmux window
- `?` lists the rest, `q` closes

---

## 8. Optional

**Per-project services.** `$DEVRC` overrides the file, so a repo can carry its own set:

```bash
DEVRC=./.devrc dev start all
```

**Keep the logs somewhere else.** `DEV_LOG_DIR` in `~/.devrc` (default `~/.cache/dev-logs`). Stop,
restart, and kill dump the pane there first, so you can still read why something died.

**Tune the panel:**

```lua
opts = {
	refresh_ms = 2000,
	preview = { height = 15, width = 0.8, lines = 200 },
	window = { width = 52, border = "rounded" },
	toggle_key = "<leader>p",
}
```

---

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| `no services defined` | no `~/.devrc` — run `dev init`, or set `$DEVRC` |
| every row `down`, but it is running | started outside `$DEV_SESSION`, or bound to a port the entry does not list |
| row stuck at `booting` | still compiling — `<Tab>` to watch it |
| row shows `dead` | the window is there but idle: it crashed or was Ctrl-C'd. `<Tab>` for why, `s` to replace it |
| `s` says "already up" | it is; `r` restarts |
| `command not found` in a window | the window runs your login shell — the command must be on the `PATH` from `~/.bashrc` |
| panel is empty | wrong `script` path in `opts`, or `bin/dev` is not executable |
| `<CR>` opens a terminal tab | you are outside tmux; that is the fallback |

---

## Removing it

```bash
dev stop all                          # frees the ports
tmux kill-session -t dev-env         # drops the windows
rm ~/.devrc                           # your service list
```

Then delete the plugin spec file and the `devpanel/` folder. Nothing else is written outside
`$DEV_LOG_DIR`.
