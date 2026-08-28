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
| **Status bar** | Off — trending repos moved to the Claude Code status line |
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

Installed by merging `claude/settings.json` into `~/.claude/settings.json`,
leaving your other settings untouched. That tracked file also carries the
`model`, `theme` and `tui` preferences — and
`skipDangerousModePermissionPrompt`, which suppresses the confirmation before
`--dangerously-skip-permissions`. Drop that key if you would rather each new
machine ask.

### Claude Code skills, commands, agents and MCP servers

Everything you teach Claude Code travels with the repo, so a new laptop starts
with the same slash commands and skills as the old one.

| Path in repo | Linked to | Holds |
|---|---|---|
| `claude/skills/` | `~/.claude/skills` | One folder per skill, each with a `SKILL.md` |
| `claude/commands/` | `~/.claude/commands` | One `.md` per slash command — `foo.md` is `/foo` |
| `claude/agents/` | `~/.claude/agents` | One `.md` per subagent |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Global instructions — routing rules, loaded every session |

These are **directory** symlinks, so anything you add later is tracked with no
further wiring: write `claude/commands/review.md`, and `/review` works at once.

```
claude/
├── commands/
│   └── digest.md                    ->  /digest
├── skills/
│   ├── docling/
│   │   └── SKILL.md                 ->  the "docling" skill
│   └── critical-developer-mindset/  ->  cloned, not vendored (see below)
└── agents/
    ├── terraform-plan-reviewer.md   ->  the "terraform-plan-reviewer" subagent
    ├── doc-researcher.md            ->  the "doc-researcher" subagent
    └── page-smoke-checker.md        ->  the "page-smoke-checker" subagent
```

**What this repo teaches the agent today.** Two of these are authored here; the
rest arrive as plugins or clones, covered further down.

| Capability | Kind | What it does |
|---|---|---|
| `/digest <file-or-folder> [out]` | command | Batch-converts PDFs, Word, PowerPoint and Excel into a Markdown corpus, writes an `INDEX.md` so later sessions read one summary instead of opening every file, and gitignores the output as a derived artifact. |
| **docling** | skill | Fires whenever a document is in play. Chooses between the MCP tools and the CLI, and enforces the rule that keeps this usable: navigate a document by anchor, never pour a 40-page PDF into the context window. Also covers the OCR cost trap — `--no-ocr` is a large speedup on digital PDFs. |

**Subagents earn their place on one test: large intermediate output, small
conclusion.** A separate context window buys exactly one thing — the bulk never
enters this session. That is why these three exist and why there are only
three; a subagent that merely knows about a topic is a worse skill.

| Subagent | Reads | Returns |
|---|---|---|
| **terraform-plan-reviewer** | A plan running to thousands of lines | A verdict — `SAFE`/`REVIEW`/`STOP` — with every destroy and replacement named, and the attribute forcing each one. Never applies. |
| **doc-researcher** | A `/digest` corpus or docs tree, potentially millions of tokens | The answer with `file § heading` citations, and an explicit note when the corpus is silent. |
| **page-smoke-checker** | Console logs, network tables and a11y snapshots across routes | A line per route: pass, fail with the causing request, or skip when a login wall made it uncheckable. |

Do not delegate interactive work — debugging where the state must stay visible
between turns belongs in the main session, and `page-smoke-checker` says so
itself rather than doing it badly.

**`claude/CLAUDE.md` routes between overlapping tools.** A skill announces
itself through its own `description`, which is what makes it fire without being
asked — so this file deliberately does not restate them. It covers only the
cases where two or more tools could plausibly answer and the description alone
would not decide: which of the three Terraform sources to use, serena versus
`/understand` versus a broad sweep, `/code-review` versus the Matt Pocock one,
and a standing rule to prefer a tool that returns ground truth over recalling
an API from training data.

It also sets one house style: **length has to earn itself** — answer first,
cut words but never facts. That is the free 90% of what prompt-compression
tooling sells, applied where the tradeoff is still yours to control, with no
proxy in front of the model rewriting these rules before it reads them.

It costs ~1.1k tokens in *every* session, including repos with no Terraform in
them, which is the reason it stays route-only. A rule that needs a paragraph
belongs in a skill, where it loads only when it is relevant.

**MCP servers** can't be symlinked — they live in `~/.claude.json`, a state file
Claude Code rewrites constantly. So `claude/mcp.json` holds the definitions and
`install.sh` merges them in, leaving every other server and all your session
state alone.

```bash
claude mcp add serena -s user -- serena start-mcp-server --context ide-assistant
claude-mcp-export     # capture this machine's servers into claude/mcp.json
```

| Server | What it gives the agent |
|---|---|
| **serena** | Semantic code navigation and editing over a real language server — `find_symbol`, `find_referencing_symbols`, `get_symbols_overview`, `get_diagnostics`, symbol-level edits and project-wide rename, across 30+ languages. Navigates by symbol instead of by grep. |
| **context7** | Version-correct documentation for any library — `resolve-library-id` then `query-docs`. Answers "what does this API actually do in the version I'm on", which a search engine cannot. |
| **graphify** | Turns a codebase — plus its docs, SQL schemas, configs and PDFs — into a knowledge graph the agent queries and cites instead of grepping. [Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify). **Unvetted — see the note below.** |
| **docling** | Reads PDFs, Word, PowerPoint, Excel and scans locally and offline. Converts a document into an anchored structure the agent navigates — overview, then search, then pull just the passages that matter — instead of pouring a 40-page PDF into the context window. |
| **terraform** | Official HashiCorp server, 9 tools over the Terraform Registry: provider schemas, resource arguments, module docs, policies. Context7 covers libraries; this covers the Registry, which it does not. |
| **chrome-devtools** | Official Google server driving a real Chrome: navigate, click, fill forms, read console errors, inspect network requests, screenshot. The one capability no CLI in this Brewfile replaces — the difference between reading the code and guessing, and opening the page and looking. |
| **gcloud** | Official Google server, a single `run_gcloud_command` tool. Thin over the CLI, but it ships a denylist for interactive and arbitrary-input commands, which raw shell access does not. Inert until `gcloud auth login`. |

`--full` installs the server binaries with `uv tool install` — `serena-agent`,
plus `docling` (the batch CLI) and `docling-mcp[local]` (the MCP server, where
the `local` extra is what keeps conversion on this machine). All three are
pinned to Python 3.13 because they pull torch, which lags the newest CPython by
months. `~/.local/bin` is already on `PATH`, so the bare commands resolve on any
machine. Context7 needs no key — one only raises rate limits. The Terraform
server is a Homebrew formula instead, and Chrome DevTools and gcloud need no
install at all — `npx` fetches the pinned version on first launch.

Docling downloads ~190 MB of layout and OCR models on first use, then runs
entirely offline. The `/digest` command and the `docling` skill drive it: the
skill picks between the MCP tools and the CLI, `/digest` batch-converts a file
or folder into a Markdown corpus with an `INDEX.md` for later sessions.

**Every server costs context in every session, and it is the biggest line in
the budget.** A skill loads a name and a description until it is invoked; an
MCP server loads *every tool's full JSON schema*, always, whether or not the
day involves a browser. Measured on this machine by listing each server's tools
and sizing the JSON:

| Server | Tools | Tokens per session |
|---|---|---|
| serena | 23 | **6,766** |
| chrome-devtools | 24 | **5,475** |
| terraform | 9 | 2,503 |
| docling | 8 | 2,327 |
| gcloud | 1 | 544 |
| **stdio total** | **65** | **~17,615** |

context7 and graphify are HTTP and not counted. For scale: that total is 12x
this repo's `CLAUDE.md` and 4x what disabling the PM plugins saves. It is also
**1.8% of a 1M context**, which is a fair price for seven servers — the point
of writing it down is that every other context argument in this file concerns
numbers an order of magnitude smaller. Tune here first, or knowingly decide not
to.

serena is the one to watch: the largest single line, and the easiest to keep
out of habit rather than use. If a month passes without reaching for symbol
navigation, dropping it recovers more than every skill decision in this file
combined. Chrome DevTools is the expensive one — 29 tools out of the box,
trimmed to 24 by `--categoryPerformance=false --categoryEmulation=false`, which
drops Lighthouse, tracing and heap snapshots. Screenshots are forced to WebP at
1280px wide because PNG screenshots are enormous in context, and usage
statistics are opted out. If a repo never touches a browser, move the server to
that project's `.mcp.json` instead of carrying it everywhere.

**Two servers launch through `npx`, which is why `{{HOME}}` exists.** fnm puts
`npx` on a per-shell ephemeral path (`fnm_multishells/<pid>_<ts>/bin`), so a
bare `npx` in `mcp.json` only resolves if Claude Code inherited a shell that had
run `fnm env`. Both point at `{{HOME}}/.local/share/fnm/aliases/default/bin/npx`
— the stable default-alias path — and `install.sh` expands `{{HOME}}` the same
way it expands `{{DOTFILES}}`. `claude-mcp-export` collapses both back into
placeholders on the way out, so re-exporting never hardcodes a username into
this repo.

**Graphify is tracked here but deliberately not vouched for.** It is
OAuth-protected (scope `graphify:query`): nothing reaches the vendor until you
run `/mcp` and sign in, and the token lives in Claude Code's credential store,
so `claude/mcp.json` carries no secret. Before you do sign in, note what the
public numbers say:

- 111.7k stars against **369 watchers** — a 303:1 ratio, where healthy popular
  repos sit near 20:1–60:1. Stars can be bought; watchers are much harder to fake.
- The repo is ~5 months old (created 2026-04-03) and the `Graphify-Labs` org is
  younger still (2026-06-28), so the repo predates the org that now owns it.
- The pitch says "on-device", yet this MCP endpoint is a hosted API at
  `api.graphify.com` that your codebase queries travel to.

None of that is proof of anything, but it is the profile of a project marketing
harder than it has earned — and the access it asks for is your source code. If
you want the graph without the vendor, the repo is Apache-2.0: run it yourself.

Then commit. On the next laptop, `./install.sh` puts them back.

**Plugins are tracked off by default.** `claude/settings.json` pins
`enabledPlugins` explicitly: the developer plugins on, the nine `pm-skills`
ones `false`. Every installed skill's name and description loads into *every*
session before you type anything — the PM set alone is 68 skills, ~4.4k tokens
of context in repos where it is never used. Measured, `mattpocock` is 37 skills
for ~1,461 tokens.

[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) was
weighed against it and rejected on that measurement: 24 skills for ~1,892
tokens of descriptions **plus a mandatory SessionStart hook that injects
~2,585 more**, for ~4,477 a session — three times the cost for a third fewer
skills, with no way to decline the hook short of forking. It is the better
repo in isolation, and the wrong trade against a set already installed and
already routed. Installed and one flag from ready beats loaded
and idle. A project that wants them turns them on in its own
`.claude/settings.json`, which outranks user scope.

Because `install.sh` replaces whole top-level keys, this file is the source of
truth: enabling a plugin through `/plugin` will be reset on the next install
unless you record it here too.

**Secrets never enter this repo.** `claude-mcp-export` skips any server with a
literal value under a key like `token`, `api_key` or `password`, and tells you
which. Two ways to keep those working:

| Approach | Where it goes |
|---|---|
| `"GITHUB_TOKEN": "${GITHUB_TOKEN}"` — Claude Code expands it at launch | tracked, safe |
| The whole server definition, secret and all | `~/.claude/mcp.local.json`, untracked, merged last |

Connectors you authorise on claude.ai — Gmail, Drive, Atlassian — are tied to
your account, not this machine, so they follow you without any config here.

### Skills and plugins that live elsewhere

`claude/external.json` lists what to fetch rather than vendor, so a skill you
maintain in its own repo stays a **live checkout** — edit it under
`claude/skills/<name>/` and push from there, with no pointer to bump here.
`install.sh` clones each one, then `pull --ff-only`s it on later runs and leaves
it alone if you have local changes. They're gitignored, so this repo never holds
a second copy.

```json
{
  "skills": {
    "critical-developer-mindset": "https://github.com/tawanorg/critical-thinking.git",
    "terraform-skill": {
      "url": "https://github.com/antonbabenko/terraform-skill.git",
      "path": "skills/terraform-skill"
    }
  },
  "marketplaces": ["anthropics/claude-plugins-official", "hashicorp/agent-skills"],
  "plugins": ["mattpocock-skills@mattpocock", "terraform@hashicorp"]
}
```

Adding one takes two edits: the entry above, and a matching `.gitignore` line.

A skill entry is **either a URL string or an object**. Use the string when
`SKILL.md` sits at the repo root. Use the object when the repo ships its skill
in a subdirectory — Claude Code only looks at exactly
`claude/skills/<name>/SKILL.md`, so a nested one would never be found. Given a
`path`, `install.sh` clones to `claude/skills/.repos/<name>` and symlinks the
subdirectory into place. Both the clone and the symlink are gitignored.

**Plugins** are registered through the `claude` CLI, which owns their on-disk
state — `install.sh` adds each marketplace and installs any plugin not already
present. To add one:

```bash
claude plugin marketplace add owner/repo
claude plugin install name@marketplace
```

then record it in `external.json` so the next laptop gets it too.

| Skill | What it does |
|---|---|
| **mattpocock-skills** | 25 skills for underspecified work: `grilling` interrogates a plan in rounds before you build, `to-spec` and `to-tickets` turn a conversation into something actionable, `triage` writes agent-ready briefs. |
| **pm-skills** (9 plugins) | The consulting side of a one-person business: NDAs and privacy policies, pricing and value-prop, ICP and go-to-market, plus `pm-ai-shipping` for auditing AI-written code (`intended-vs-implemented`, `ship-check`). |
| **understand-anything** | Builds a queryable knowledge graph of a codebase, then answers from it: `/understand` maps architecture into layers, `/understand-explain` deep-dives one file or module, `/understand-diff` reads a PR for affected components and risk, `/understand-onboard` writes the guide for someone joining. Aimed at the codebase you have just inherited. |
| **terraform-skill** | One diagnosis-first skill for *using* Terraform/OpenTofu: it categorises the failure mode — identity churn, secret exposure, blast radius, CI drift, state corruption — before proposing a fix, and forces every answer to state its version floor and tradeoffs. [antonbabenko/terraform-skill](https://github.com/antonbabenko/terraform-skill). |
| **terraform@hashicorp** | HashiCorp's official plugin, 16 skills. Worth knowing the weighting: nine are about *authoring* Terraform providers in Go (`new-terraform-provider`, `provider-framework-migration`, `run-acceptance-tests`). The rest apply to consuming Terraform — `terraform-style-guide`, `terraform-test`, `refactor-module`, `terraform-stacks`, `terraform-search-import`, `terraform-policy`. |
| **document-skills@anthropic** | Anthropic's official document suite — `xlsx`, `docx`, `pptx`, `pdf`. The complement to docling: docling *reads* a deck, these *produce* one. Its sibling `example-skills` plugin is deliberately not installed — `skill-creator`, `frontend-design` and `mcp-builder` already ship in `claude-plugins-official`. |
| **critical-developer-mindset** | A 7-step pass over any ticket — question, research, validate, expand, secure, future, implement — on the principle that *AC is scope, not specification*. Written for tickets that arrive underspecified. |

### Toolchain — 45 formulae, 7 casks

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
| **Cloud & IaC** | terraform, terraform-mcp-server, tflint, awscli, gcloud |
| **System** | htop, btop, httpie, wget, watch, tldr, coreutils, gnu-sed |
| **Apps** | iTerm2, VS Code, Slack, MesloLGS + JetBrains Mono Nerd Fonts |

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
| `~/.cache/gh-trending.json` | full records — name, URL, stars, the query that found it | `trending`, `trending-open` |
| `~/.cache/gh-trending.names` | plain `owner/repo`, one per line | `claude-statusline` (`sed`, no decoding) |

The status line picks its group of five from the wall clock (`epoch / 1800`), so
the display holds still for a full 30 minutes and needs no stored state. A
background refresh runs at most once every 6 hours, from `.zshrc`, detached —
nothing blocks the prompt.

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
- **`~/.claude/settings.json` and `~/.claude.json`** — not symlinked, because
  Claude Code rewrites both. `install.sh` merges in the keys from
  `claude/settings.json` and the servers from `claude/mcp.json`.
- **MCP secrets** — live in `~/.claude/mcp.local.json`, untracked, so this repo
  can stay public. `install.sh` merges it last.
- **Machine-specific shell config** — put it in `~/.zshrc.local`, sourced last.

## Layout

| Path | Linked to |
|---|---|
| `home/*` | `~/.<name>` — zshrc, zsh_plugins.txt, gitconfig, tmux.conf … |
| `config/*` | `~/.config/` — starship, nvim, bat |
| `iterm2/dev.json` | iTerm2 DynamicProfiles |
| `claude/skills`, `claude/commands`, `claude/agents` | `~/.claude/` — Claude Code skills, slash commands, subagents |
| `claude/settings.json`, `claude/mcp.json` | merged into `~/.claude/settings.json` and `~/.claude.json` |
| `claude/external.json` | skills cloned from their own repos; marketplaces and plugins |
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
