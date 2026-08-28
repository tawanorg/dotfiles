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


info "Linking Claude Code skills, commands and agents"
link "$DOTFILES/claude/skills"   "$HOME/.claude/skills"
link "$DOTFILES/claude/commands" "$HOME/.claude/commands"
link "$DOTFILES/claude/agents"   "$HOME/.claude/agents"
if [[ -e "$DOTFILES/claude/CLAUDE.md" ]]; then
  link "$DOTFILES/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
fi

# Claude Code rewrites ~/.claude/settings.json and ~/.claude.json itself, so
# neither can be symlinked. Merge our keys in, leaving everything else alone.
if command -v python3 >/dev/null; then
  info "Merging Claude Code settings and MCP servers"
  DOTFILES="$DOTFILES" python3 - <<'PYEOF'
import json, os, tempfile

DOTFILES = os.environ["DOTFILES"]
HOME = os.path.expanduser("~")


def load(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except FileNotFoundError:
        return default
    except json.JSONDecodeError:
        print(f"    warn {path} is not valid JSON - leaving it alone")
        raise SystemExit(0)


def save(path, data):
    """Write atomically: a half-written ~/.claude.json would lose real state."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path))
    with os.fdopen(fd, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    os.replace(tmp, path)


def expand(value):
    """Substitute {{DOTFILES}} so tracked paths work from any clone location."""
    if isinstance(value, str):
        return value.replace("{{DOTFILES}}", DOTFILES)
    if isinstance(value, dict):
        return {k: expand(v) for k, v in value.items()}
    if isinstance(value, list):
        return [expand(v) for v in value]
    return value


# settings.json - our tracked keys win, any local-only key is preserved.
tracked = expand(load(f"{DOTFILES}/claude/settings.json", {}))
settings_path = f"{HOME}/.claude/settings.json"
settings = load(settings_path, {})
settings.update(tracked)
save(settings_path, settings)
print(f"    settings {', '.join(sorted(tracked))}")

# MCP servers live in ~/.claude.json under "mcpServers" (user scope). Secrets
# stay out of this repo: put those servers in ~/.claude/mcp.local.json, which
# is untracked and merged last.
servers = expand(load(f"{DOTFILES}/claude/mcp.json", {}).get("mcpServers", {}))
servers.update(load(f"{HOME}/.claude/mcp.local.json", {}).get("mcpServers", {}))
if servers:
    config_path = f"{HOME}/.claude.json"
    config = load(config_path, {})
    config.setdefault("mcpServers", {}).update(servers)
    save(config_path, config)
    print(f"    mcp {', '.join(sorted(servers))}")
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
