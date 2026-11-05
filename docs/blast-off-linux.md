# blast-off.linux.sh

`blast-off.linux.sh` does not exist yet. Write it on the Arch Linux computer.
Until it exists, `blast-off.sh` stops on Linux with a pointer to this file.

## Contract

`blast-off.sh` runs the scripts in this order:

1. `blast-off.linux.sh`: OS packages and OS settings.
2. Generic setup in `blast-off.sh`: symlinks, directories, Node, tmux, Neovim,
   and the login shell.
3. `~/.dotfiles-work/blast-off.sh`: only when you answer "yes" to the work
   question. That repo is a private overlay.

`blast-off.linux.sh` must:

- Start with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Source `blast-off.lib.sh`, call `blast_off_log_start "$@"`, and run each
  step with `run "<description>" <command>`. A failed step is then recorded
  in the shared logs and the next step runs. Use `die` only when later steps
  cannot work, and end with `finish`. See `blast-off.mac.sh`.
- Be safe to run again. Use `pacman -S --needed`, `mkdir -p`, and
  `[[ -d x ]] || git clone`.
- Run on its own, not only from `blast-off.sh`.
- Install every command that the generic step uses: `git`, `curl`, `zsh`,
  `fnm`, `neovim`, and `tmux`.
- Not touch `~/.config`. The generic step backs it up to `~/.config.bak` and
  replaces it with a symlink to `~/.dotfiles/config`.

## Packages

Keep the list in `packages/pacman.txt`, one package on each line. Install it
with:

```bash
sudo pacman -S --needed - < "$DOT/packages/pacman.txt"
```

Start from the macOS `packages/Brewfile`. The likely Arch names are:

| Purpose | Packages |
| --- | --- |
| Required by `blast-off.sh` | `git` `curl` `zsh` `fnm` `neovim` `tmux` |
| Shell | `bat` `eza` `fzf` `ripgrep` `jq` |
| Git | `github-cli` `git-delta` `git-lfs` |
| Clipboard (`tmux.conf` uses `wl-copy`) | `wl-clipboard` |
| Apps | `kitty` `mpv` `qutebrowser` `keepassxc` `ttf-firacode-nerd` |
| Desktop | `hyprland` `hyprpaper` |

Use an AUR helper such as `paru` for packages that are not in the official
repositories. Install the helper inside the script, behind a
`command -v paru` guard.

## Linux-specific setup

- Secrets: `bin/secret` and `kpdb-pass` in `.zshrc` use the macOS `security`
  command. On Linux, store the KeePassXC password with `secret-tool`
  (package `libsecret`), and branch on `uname` in both places.
- Services: enable user services with `systemctl --user enable --now <unit>`.

## Mac-only lines that break on Linux

Fix these before you run `blast-off.sh` on Linux:

| File | Problem |
| --- | --- |
| `config/zsh/.zprofile` | Runs `/opt/homebrew/bin/brew shellenv` with no guard. |
| `config/zsh/.zprofile` | Defines `sourceIfAvailable`, but non-login shells on Linux do not read `.zprofile`. `.zshrc` calls it. Move the helpers to `.zshenv`. |
| `config/zsh/.zshenv` | Sources `$HOME/.cargo/env` with no guard. |
| `.gitconfig` | The credential helper path is `/opt/homebrew/bin/gh`. Use `!gh auth git-credential`. |
| `config/nvim/ftplugin/java.lua` | The jdtls path is `/opt/homebrew/Cellar/jdtls`. |
| `config/tmux/tmux.conf` | The `ccmux` binding uses `/Users/chinedumu/...`. |

## Work setup on Linux

The private work overlay (`~/.dotfiles-work`) documents this in
`docs/linux.md`.
