# Dotfiles Setup

## Requirements

Make sure you have the following tools installed:

- [`fzf`](https://github.com/junegunn/fzf) – Fuzzy search
- [`rg`](https://github.com/BurntSushi/ripgrep) – File search (ripgrep)
- [`fd`](https://github.com/sharkdp/fd) – Alternative to `find`
- [`stow`](https://www.gnu.org/software/stow/) – For managing symlinks in this config
- [`tmux`](https://github.com/tmux/tmux) – For terminal multiplexer

## Worktree Selector

To enable the **worktree-selector**, register it inside your `~/.profile` or `~/.bashrc`:

```bash
export APP_PATH="extra path"
export API_PATH="extra path"

alias qwe='. ~/.local/bin/worktree-selector'
```
