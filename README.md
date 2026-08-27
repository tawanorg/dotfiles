# dotfiles

macOS full-stack dev environment: zsh + starship, iTerm2, and the toolchain.

## Install on a new machine

```bash
git clone git@github.com:tawanorg/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --full     # symlinks + Homebrew + Node + macOS settings
```

`./install.sh` on its own only creates the symlinks — no installs, no system
changes. It is safe to re-run: anything it replaces is copied to
`~/.dotfiles-backup/<timestamp>/` first.

## Layout

| Path | Linked to |
|---|---|
| `home/*` | `~/.<name>` — zshrc, zsh_plugins.txt, gitconfig, tmux.conf … |
| `config/*` | `~/.config/` — starship, nvim, bat |
| `iterm2/dev.json` | iTerm2 DynamicProfiles — the "Dev" profile |
| `macos/defaults.sh` | system settings (keyboard, menu bar, Finder, iTerm2) |
| `Brewfile` | every formula and cask |

## Not tracked

`~/.gitconfig.local` holds the git name and email so this repo can be public —
`install.sh` prompts for them on a fresh machine. `~/.zshrc.local` is sourced at
the end of `.zshrc` for anything machine-specific.

## Shell

Plugins are managed by [antidote](https://antidote.sh) from `home/zsh_plugins.txt`.
Edit that file and run `reload` — the static cache rebuilds automatically.
Startup is ~180ms with 28 plugins.

Worth knowing:

| Key | Does |
|---|---|
| `→` / `Ctrl-Space` | accept the autosuggestion |
| `Ctrl-→` | accept one word of it |
| `ESC` `ESC` | prepend `sudo` to the line you already typed |
| `Ctrl-R` / `Ctrl-T` | fzf history / file search |
| `Ctrl-O` | copy the current command line |
| `Enter` (empty line) | `git status -sb` in a repo, else `ls` |

## iTerm2 status bar: trending repos

Claude Code's status line and the iTerm2 status bar both show **5** interesting
self-hosted / AI / MCP / dev-tooling repos, rotating to the next 5 every
**30 minutes**. In Claude Code each name is an OSC 8 hyperlink — click to open
the repo. 25 groups cover a 12.5-hour cycle.

```bash
gh-trending --refresh   # force a fetch (also runs in the background when >6h old)
trending                # page through everything cached
trending-open           # open the current repo in a browser
```

`bin/gh-trending` queries the GitHub search API across several topics, dedupes,
and writes pre-rendered base64 lines to `~/.cache/gh-trending.lines`. The zsh
`precmd` hook does nothing but `printf` one of those lines as an iTerm2 user
variable, so it adds no measurable cost per prompt. The status bar shows it via
the interpolated string `\(user.trending)`.

Unauthenticated the search API allows 10 requests/min, which is plenty at a 6h
refresh. If `gh auth login` has been run, the script picks up that token
automatically and gets 5000/hr.

## macOS settings

`macos/defaults.sh` remaps **⌘Space to switch input source** (Spotlight moves to
**⌥Space**), shows the language indicator and battery percentage in the menu bar,
and applies Finder/keyboard defaults.

## Docker

Docker Desktop needs a password to install, so this uses colima instead:

```bash
colima start --cpu 4 --memory 8 --disk 60
```
