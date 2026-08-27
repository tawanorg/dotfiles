#!/usr/bin/env bash
# Bootstrap this machine. Safe to re-run: existing files are backed up once,
# and symlinks that already point at the repo are left alone.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
ITERM_PROFILES="$HOME/Library/Application Support/iTerm2/DynamicProfiles"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

link() {  # link <source-in-repo> <target-path>
  local src="$1" dst="$2"
  [[ -e $src ]] || { warn "missing in repo: $src"; return; }
  if [[ -L $dst && "$(readlink "$dst")" == "$src" ]]; then
    printf '    ok   %s\n' "${dst/#$HOME/\~}"; return
  fi
  if [[ -e $dst || -L $dst ]]; then
    mkdir -p "$BACKUP/$(dirname "${dst#$HOME/}")"
    mv "$dst" "$BACKUP/${dst#$HOME/}"
    printf '    bak  %s\n' "${dst/#$HOME/\~}"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  printf '    link %s\n' "${dst/#$HOME/\~}"
}

info "Linking home dotfiles"
for f in "$DOTFILES"/home/*; do
  link "$f" "$HOME/.$(basename "$f")"
done

info "Linking ~/.config"
link "$DOTFILES/config/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES/config/nvim/init.lua" "$HOME/.config/nvim/init.lua"
link "$DOTFILES/config/bat/config"    "$HOME/.config/bat/config"

info "Linking iTerm2 dynamic profile"
mkdir -p "$ITERM_PROFILES"
link "$DOTFILES/iterm2/dev.json" "$ITERM_PROFILES/dev.json"

# Git identity is deliberately untracked so this repo can be public.
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  info "Creating ~/.gitconfig.local (git identity — not tracked)"
  read -rp "    Your git name:  " GIT_NAME
  read -rp "    Your git email: " GIT_EMAIL
  cat > "$HOME/.gitconfig.local" <<EOF
[user]
	name = $GIT_NAME
	email = $GIT_EMAIL
EOF
fi


# The Claude Code status line lives in ~/.claude/settings.json, which Claude
# Code rewrites itself — so it is not symlinked. Merge our key in, leaving
# every other setting untouched.
if command -v python3 >/dev/null; then
  info "Wiring the Claude Code status line"
  DOTFILES="$DOTFILES" python3 - <<'PYEOF'
import json, os
p = os.path.expanduser("~/.claude/settings.json")
os.makedirs(os.path.dirname(p), exist_ok=True)
try:
    with open(p) as f:
        settings = json.load(f)
except Exception:
    settings = {}
settings["statusLine"] = {
    "type": "command",
    "command": os.path.join(os.environ["DOTFILES"], "bin", "claude-statusline"),
    "padding": 0,
}
with open(p, "w") as f:
    json.dump(settings, f, indent=2)
print(f"    statusLine -> {settings['statusLine']['command']}")
PYEOF
fi

if [[ "${1:-}" == "--full" ]]; then
  info "Installing Homebrew packages (this takes a while)"
  command -v brew >/dev/null || {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  }
  brew bundle --file="$DOTFILES/Brewfile"

  info "Installing Node LTS"
  eval "$(fnm env --shell bash)" && fnm install --lts && fnm default lts-latest

  info "Applying macOS system settings"
  bash "$DOTFILES/macos/defaults.sh"
fi

[[ -d $BACKUP ]] && info "Replaced files backed up to ${BACKUP/#$HOME/\~}"
info "Done. Run 'exec zsh' to load the new shell."
