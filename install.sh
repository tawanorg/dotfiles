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

# Skills that live in their own repo stay a live checkout (gitignored here), so
# you can edit and push them without bumping a pointer in this repo.
if command -v python3 >/dev/null; then
  while IFS=$'\t' read -r name url; do
    [[ -n $name ]] || continue
    dest="$DOTFILES/claude/skills/$name"
    if [[ -d $dest/.git ]]; then
      git -C "$dest" pull --ff-only --quiet 2>/dev/null \
        && printf '    pull %s\n' "$name" \
        || warn "could not update $name (local changes?) - left alone"
    else
      info "Cloning skill $name"
      git clone --quiet "$url" "$dest" || warn "clone failed: $url"
    fi
  done < <(python3 -c '
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except FileNotFoundError:
    raise SystemExit
for name, url in (d.get("skills") or {}).items():
    print(f"{name}\t{url}")
' "$DOTFILES/claude/external.json")
fi

# Marketplaces and plugins go through the CLI, which owns their on-disk state.
if command -v claude >/dev/null && command -v python3 >/dev/null; then
  reg() { python3 -c '
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except FileNotFoundError:
    raise SystemExit
print("\n".join(d.get(sys.argv[2]) or []))
' "$DOTFILES/claude/external.json" "$1"; }

  while read -r src; do
    [[ -n $src ]] || continue
    claude plugin marketplace add "$src" >/dev/null 2>&1 \
      && printf '    marketplace %s\n' "$src" \
      || printf '    ok   marketplace %s\n' "$src"
  done < <(reg marketplaces)

  while read -r plugin; do
    [[ -n $plugin ]] || continue
    if claude plugin list 2>/dev/null | grep -q "${plugin%%@*}"; then
      printf '    ok   plugin %s\n' "$plugin"
    else
      info "Installing plugin $plugin"
      claude plugin install "$plugin" -y --scope user || warn "install failed: $plugin"
    fi
  done < <(reg plugins)
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
    """Substitute {{DOTFILES}} and {{HOME}} so tracked paths work anywhere.

    {{HOME}} matters for MCP servers launched through a version manager: fnm's
    `npx` lives on a per-shell ephemeral path, so a bare `npx` only resolves if
    Claude Code happened to inherit a shell that had run `fnm env`. Pointing at
    the stable default-alias path instead makes the server start either way.
    """
    if isinstance(value, str):
        return value.replace("{{DOTFILES}}", DOTFILES).replace("{{HOME}}", HOME)
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

  info "Installing uv tools"
  # MCP server binaries; the servers themselves are declared in claude/mcp.json.
  # Pinned to 3.13: these pull torch, which lags the newest CPython by months.
  uv tool install -p 3.13 serena-agent
  # docling = the CLI (batch conversion); docling-mcp = the MCP server. The
  # [local] extra is what makes conversion run on this machine instead of
  # calling out to a docling-serve instance.
  uv tool install -p 3.13 docling
  uv tool install -p 3.13 "docling-mcp[local]"

  info "Installing Node LTS"
  eval "$(fnm env --shell bash)" && fnm install --lts && fnm default lts-latest

  info "Applying macOS system settings"
  bash "$DOTFILES/macos/defaults.sh"
fi

[[ -d $BACKUP ]] && info "Replaced files backed up to ${BACKUP/#$HOME/\~}"
info "Done. Run 'exec zsh' to load the new shell."
