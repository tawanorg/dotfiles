# Software engineer agent

Start a new Codex session, then ask:

> Use the software_engineer agent to implement [change]. Done means [observable behavior].

For a bug, include what happens, what should happen, and a reproduction if known.
Assign an existing worktree and file ownership when other sessions are editing.
For tiny edits, working directly in the parent avoids the extra agent context.

## Installation and portability

`software-engineer.toml` is a personal agent under the active Codex home's
`agents/` directory. To reuse it on another machine, copy that file to the
equivalent directory and start a new session. Project-scoped installation uses
`.codex/agents/software-engineer.toml`. Avoid defining the same role in both
places unless an intentional project override is desired.

The agent inherits the parent model, reasoning effort, MCP connections, and
permission settings. It has no embedded provider credentials or project paths.
Its LLM work uses the parent session's authentication and billing arrangement;
with subscription-authenticated Codex it consumes that subscription's allowance.
Separate services can have their own billing. Inheritance does not make them free.

## Tool choices

| Need | Preferred tool | Fallback |
| --- | --- | --- |
| Locate code and callers | Serena symbol definitions/references | Scoped rg and file reads |
| Check a library API | Context7 or the project's dedicated docs MCP | Official version-matched docs |
| Public web research | Firecrawl MCP or CLI; narrow queries, cached results | Available approved web tool |
| Verify behavior | Project tests, lint, typecheck, browser/device tools | Report unverified behavior explicitly |
| Review substantial changes | Open Code Review delegation skill | Explicit self-review |

Connections come from the host session. Copying the TOML file alone does not
install MCP servers or skills. Existing tools are reused, and missing optional
tools have fallbacks. Credentials stay in the host configuration/environment.
OCR-managed API calls require explicit authorization. Firecrawl's hosted service
can consume separate credits; local Serena navigation does not require an LLM API key.

## Working style

Understand the relevant path, implement a complete change, verify the observable
result. Small tasks proceed directly. Larger changes use a short working plan;
project-required financial, security, migration, and review gates still apply.
Routine test boundaries are inferred from approved behavior and existing patterns.
Specialist skills load only for the relevant task, rather than starting a fixed
chain of interviews and documents for every edit.

The host can still bring a large tool/skill catalog into context. Selective tool
use limits retrieved output but does not remove that startup cost. Disable unused
plugins in the host deliberately if that becomes a measured problem. No percentage
token savings or enterprise reliability claim has been established for this agent.

## Sources and design decisions

Reviewed 2026-09-10. These are references, not installed nested coding agents.

- [Matt Pocock skills](https://github.com/mattpocock/skills): small composable skills, public-interface tests, short feedback loops. Uses the already installed bundle; preserves the user's preference for minimal ceremony.
- [Serena](https://github.com/oraios/serena): semantic code navigation can retrieve definitions and references without loading entire files. Actual savings depend on task and language support.
- [Aider](https://github.com/Aider-AI/aider): immediate lint/test feedback is a useful implementation practice. Aider itself is a separate coding client and was not installed; its API setup is unnecessary for this Codex agent.
- [OpenHands](https://github.com/OpenHands/OpenHands): Agent Canvas supports local/remote agent backends and automations. Consider it for always-on infrastructure or team orchestration; those concerns are outside this personal agent's job.
- [Codex custom agents](https://learn.chatgpt.com/docs/agent-configuration/subagents): personal/project TOML agent definitions and inherited settings.

## Evaluation

A valid TOML file only establishes parseability. A meaningful trial must launch
the actual custom role, exercise an implementation with a failing regression test,
rerun it after the fix, and check unrelated work was preserved. A small fixture is
a smoke test, not a benchmark of production engineering quality. Repeat on actual
tasks before making claims about speed, cost, or reliability.

2026-09-10 smoke result: a normal Codex CLI session successfully launched exactly
one `software_engineer` role on a disposable Node.js pagination fixture. The agent
reported 3 failing and 2 passing tests before the fix; independent reruns after
the fix passed all 5 tests. The unrelated notes file retained its SHA-256 checksum.
The agent configuration omitted model/reasoning/tool overrides. This trial did
not exercise Serena, Firecrawl, UI tools, or a complete OCR review.

An earlier `codex exec --ephemeral` launch failed with `collab spawn failed: no
thread with id`. A regular session succeeded; use that path for this installation.
The host also warned that skill descriptions were shortened to fit its context
budget. These are observed limitations, not proven problems in other versions.
