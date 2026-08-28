# Global instructions

Loaded into every session, in every repo, before anything else. Keep it short
and route-only: rules for choosing *between* overlapping tools. Skills already
announce themselves through their own descriptions — do not restate those here.
Anything that needs a paragraph belongs in a skill, which loads only when
relevant.

## Length has to earn itself

Answer first, evidence after. No preamble, no restating the question, no
summary of what you just did when the work is visible.

Cut words, never facts. Terse is `src/api.ts:42 — the retry loop never resets
the counter`; vague is "there's an issue with the retry logic". Keep the file,
the line, the number, the exact resource name — those *are* the answer. A
two-line reply to a two-line question is correct, not lazy; three paragraphs
of throat-clearing before the fix is the actual failure.

Prose earns its place where code cannot speak: a tradeoff, a risk, a reason.
Not to narrate a diff the user can read.

## Ground truth over recall

Where a tool can return the real answer, never answer from memory:

| Question | Tool |
|---|---|
| A library or framework's API, config, or migration path | **context7** MCP |
| A Terraform provider's arguments, a module's docs | **terraform** MCP (Registry) |
| What a page actually does — console errors, network, layout | **chrome-devtools** MCP |
| What a PDF, deck, or spreadsheet says | **docling** skill |
| Where a symbol is defined or used | **serena** MCP |

Training data goes stale and these do not. A confident wrong version number
costs more than the tool call.

## Terraform and OpenTofu

When a task touches `.tf` / `.tofu` files, a module, a plan or apply, remote
state, or a Terraform CI job, **invoke `terraform-skill` before proposing
changes** — including when the Terraform is incidental to the request ("the CI
is broken", "the deploy recreated the database"). Three sources overlap:

| Question | Use |
|---|---|
| "Why is this breaking?" · "What will this destroy?" · "Safe to apply?" | **terraform-skill** — risk and diagnosis: identity churn, blast radius, state corruption, secrets, CI drift |
| Canonical style, testing, refactoring, stacks, policy, import | **`terraform@hashicorp`** skills — the authoritative spec |
| Writing a Terraform *provider* in Go | **`terraform@hashicorp`** `provider-*`, `run-acceptance-tests` |

When risk and syntax both apply, take the framing from `terraform-skill` and
the exact spec from HashiCorp.

## Understanding code you did not write

Three tools overlap; they answer different shapes of question:

- **serena** — a specific symbol. "Where is this defined, who calls it, rename
  it." Precise and cheap. Prefer it over grep for anything symbol-shaped.
- **understand-anything** (`/understand`, `/understand-explain`, `/understand-diff`)
  — the whole system. Architecture, layers, how a change ripples. Worth its
  cost on a codebase you have just inherited, not on one you know.
- **Explore agent** — a broad sweep where only the conclusion matters and the
  file dumps do not.

## Delegating to a subagent

Delegate when the work produces **large intermediate output but a small
conclusion** — a Terraform plan, a document corpus, a sweep of routes. The
separate context window is the point: the bulk stays out of this session.
Do not delegate interactive work, where you need the state visible between
turns. `terraform-plan-reviewer`, `doc-researcher` and `page-smoke-checker`
are local; write more in `claude/agents/` when the same shape recurs.

## Reviewing

`/code-review` (built in) and `mattpocock-skills:code-review` both exist and do
different jobs. Use `/code-review` for correctness on a diff. Use the Matt
Pocock one when the question is whether the change matches a written spec or
the repo's documented standards. Say which you ran.

## Scope

`critical-developer-mindset` declares itself always-on. Treat it as applying to
underspecified features, tickets and bug reports — where questioning the
requirement is the value. Skip it for mechanical, fully specified requests; a
one-line fix does not need a 7-step interrogation.

The `pm-skills` plugins are installed but disabled on purpose. A project that
wants them enables them in its own `.claude/settings.json`.
