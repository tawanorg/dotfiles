# dotfiles

A complete macOS full-stack dev environment: terminal, shell, toolchain and
system settings. One command on a fresh machine.

```bash
git clone git@github.com:tawanorg/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh --full
```

---

## What you get

### Terminal — iTerm2, installed and configured

`--full` installs iTerm2 itself, so you do **not** need to set it up first.

| | |
|---|---|
| **App** | iTerm2 installed via Homebrew cask |
| **Profile** | A dynamic profile named **Dev**, set as the default for new windows |
| **Font** | MesloLGS Nerd Font Mono 14 (JetBrains Mono Nerd Font also installed) |
| **Colours** | Catppuccin Mocha |
| **Scrollback** | Unlimited |
| **Keys** | `⌥←/→` by word · `⌘←/→` line ends · `⌥⌫` delete word · `⌘⌫` delete to start |
| **Status bar** | Enabled, showing trending repos |
| **Behaviour** | No quit prompt, minimal tabs, selection copies, inactive panes dimmed |

The profile is a *dynamic profile* — a JSON file iTerm2 reads on launch. It
survives app updates and can't be clobbered by the preferences UI.

### Shell — zsh, ~180ms startup, 28 plugins

Plugin manager is [antidote](https://antidote.sh); the prompt is
[starship](https://starship.rs) in plain text (no glyph fonts required).

**Suggestions and safety**

| Plugin | What it does |
|---|---|
| zsh-autosuggestions | Ghost text from history **and** completions |
| fast-syntax-highlighting | Commands colour as you type; typos are obvious |
| fzf-tab | Fuzzy menu on `TAB` with file previews |
| zsh-autopair | Closes quotes and brackets |
| you-should-use | Tells you when an alias already exists for what you typed |
| safe-paste | Pasted text never auto-runs |

**Keys worth knowing**

| Key | Does |
|---|---|
| `→` or `Ctrl-Space` | Accept the autosuggestion |
| `Ctrl-→` | Accept one word of it |
| `ESC` `ESC` | Prepend `sudo` to the line you already typed |
| `Ctrl-R` / `Ctrl-T` | fzf history / file search |
| `Ctrl-O` | Copy the current command line |
| `Enter` on an empty line | `git status -sb` in a repo, else `ls` |

Plus `z <dir>` frecency jump, `mkcd`, `killport 3000`, `gclone <url>`,
`extract <any-archive>`, and git/pnpm/docker aliases.

### Claude Code status line

```
Opus 5 1M high  ·  ~/dotfiles main  ·  ctx 73%  ·  5h 1% 7d 2%
mudler/LocalAI / bytedance/deer-flow / aden-hive/hive / khoj-ai/khoj / …
```

| Field | Meaning |
|---|---|
| `ctx 73%` | Context remaining. Green → **yellow under 35%** → **red under 15%**: time to `/compact` |
| `5h` / `7d` | Rate-limit budget used. Dim → yellow at 70% → red at 90% |
| `high` | Reasoning effort level |
| `+120/-8` | Lines added/removed this session, when non-zero |
| Row 2 | 5 trending repos, rotating every 30 min — each name is a clickable link |

Installed by merging a `statusLine` key into `~/.claude/settings.json`,
leaving your other settings untouched.

### Toolchain — 44 formulae, 6 casks

| Area | Tools |
|---|---|
| **Shell** | starship, antidote, zoxide, direnv, fzf |
| **Files & search** | eza, bat, fd, ripgrep, tree, jq, yq |
| **Git** | git, gh, git-delta, lazygit |
| **Editor & mux** | neovim, tmux |
| **Node** | fnm (auto-switches per `.nvmrc`), Node LTS, pnpm, yarn, bun |
| **Python** | uv, pyenv, pipx, ruff |
| **Go** | go, golangci-lint |
| **Containers** | colima, docker, docker-compose, docker-buildx, lazydocker, dive |
| **Cloud & IaC** | terraform, tflint, awscli, gcloud |
| **System** | htop, btop, httpie, wget, watch, tldr, coreutils, gnu-sed |
| **Apps** | iTerm2, Slack, MesloLGS + JetBrains Mono Nerd Fonts |

Git comes configured with delta diffs, `pull --rebase`, `push` auto-setting
upstream, `rerere`, and aliases (`git s`, `git lg`, `git sync`, `git cleanup`).

### macOS system settings

- **`⌘Space` switches input source** (e.g. US ↔ Thai); Spotlight moves to **`⌥Space`**
- Menu bar: language indicator, battery **percentage**, Sound, Bluetooth
- Finder: show hidden files, all extensions, path + status bar, list view, folders first
- Keyboard: fast key repeat, no press-and-hold accents, no smart quotes/dashes
- Screenshots save to `~/Downloads` without shadows

### Trending repos

`bin/gh-trending` queries the GitHub search API across self-hosted, LLM,
AI-agent, MCP and developer-tooling topics, then pre-renders the results so
display costs nothing:

| Cache file | Contents | Used by |
|---|---|---|
| `.names` | plain `owner/repo` | `claude-statusline` (`sed`, no decoding) |
| `.groups` | base64 of 5 names joined | iTerm2 user var (`printf` only) |

Both pick their group from the wall clock (`epoch / 1800`), so the display holds
still for a full 30 minutes and needs no stored state. The zsh `precmd` hook
spawns no subprocess.

```bash
trending          # page through everything cached
trending-open     # open the current repo
gh-trending --refresh
```

Snapshots are archived daily to
**[tawanorg/trending-open-sources](https://github.com/tawanorg/trending-open-sources)**
by GitHub Actions, so nothing that scrolls past is lost.

---

## Install

```bash
./install.sh          # symlinks only — no installs, no system changes
./install.sh --full   # the above + Homebrew + Brewfile + Node LTS + macOS settings
```

Re-runnable: it reports `ok` for links already in place. Anything it replaces is
moved to `~/.dotfiles-backup/<timestamp>/` first, never deleted.

On a fresh machine it prompts once for your **git name and email**.

**Run it from Terminal.app, not iTerm2** — `macos/defaults.sh` writes iTerm2
preferences, and a running iTerm2 overwrites them on quit.

### After it finishes

```bash
exec zsh                                  # load the new shell
gh auth login                             # GitHub CLI
colima start --cpu 4 --memory 8 --disk 60 # start Docker (first run pulls a VM image)
aws configure && gcloud init              # if you use them
```

Then open a **new iTerm2 window** to pick up the Dev profile.

## Not included, on purpose

- **Docker Desktop** — its installer needs a sudo password, so this uses
  **colima** + the docker CLI instead: free, lighter, no admin rights. `docker`
  and `docker compose` work normally.
- **Git identity** — lives in `~/.gitconfig.local`, untracked, so this repo can
  stay public. The tracked `gitconfig` pulls it in via `[include]`.
- **`~/.claude/settings.json`** — not symlinked, because Claude Code rewrites it.
  `install.sh` merges in only the `statusLine` key.
- **Machine-specific shell config** — put it in `~/.zshrc.local`, sourced last.

## Layout

| Path | Linked to |
|---|---|
| `home/*` | `~/.<name>` — zshrc, zsh_plugins.txt, gitconfig, tmux.conf … |
| `config/*` | `~/.config/` — starship, nvim, bat |
| `iterm2/dev.json` | iTerm2 DynamicProfiles |
| `bin/*` | on `PATH` via `.zshrc` |
| `macos/defaults.sh` | system settings (not linked — run by `--full`) |
| `Brewfile` | every formula and cask |

Your live configs are symlinks into this repo, so editing `~/.zshrc` edits the
tracked file directly — no copy step to forget.

## Customising

Add or remove plugins in `home/zsh_plugins.txt`, then run `reload`. The static
plugin cache rebuilds only when that file changes, which is what keeps startup
at ~180ms.

To update the package list after installing something new:

```bash
brew bundle dump --file=Brewfile --force
```

## Notes

- Homebrew's prefix is detected, so Intel Macs work as well as Apple Silicon.
- Some macOS settings need a logout to take full effect.
