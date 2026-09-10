# Software Engineer for Codex

A reusable implementation workflow for your team's existing Codex setup.
Give it a feature, bug, or refactor; it reads the relevant code, makes the
change, and checks that the requested behavior works.

It is useful across projects because it discovers each repository's stack,
commands, and conventions. It inherits your selected Codex model and permissions.

## What it does

1. **Understands the task.** Reads project instructions, locates the code and its
   callers, and identifies what would demonstrate success. Asks about missing
   product decisions when they affect the implementation.
2. **Implements the change.** Follows existing patterns, preserves unrelated work,
   and updates affected callers and error handling. Adds meaningful regression
   coverage for bugs where feasible.
3. **Verifies the result.** Runs relevant tests and project-required checks,
   inspects the diff, and reports what passed and what remains unverified.

Small tasks proceed directly. Larger tasks get a short working plan. The workflow
does not require a separate planning interview for every edit. Repository rules
for security, financial calculations, migrations, and approvals still apply.

## Use it

Start a new Codex conversation inside the project after installation. Select
**Software Engineer** in the skills picker or type:

```text
$software-engineer implement pagination for the customer list. Show 20 customers
per page and preserve the current filters when switching pages.
```

Other examples:

```text
$software-engineer fix the search filter resetting when I return from a detail page.
Add a regression test and run the relevant checks.
```

```text
$software-engineer refactor the CSV parser while preserving its public behavior.
Work in the current thread.
```

Describe the desired behavior and any constraints. For bugs, include reproduction
steps or an error message if you have them. You do not need to name every tool.

The **skill** (`software-engineer`, with a hyphen) is the selectable entry point.
The **custom agent** (`software_engineer`, with an underscore) is a role Codex can
spawn for a bounded implementation assignment. Both use the same instructions.
The custom role itself is not an `@` plugin picker entry.

For small tasks the skill can work in the current conversation. For useful
delegated work it can launch the custom agent; if that role is unavailable it
uses the same instructions in the current conversation and says so. To avoid
the extra context of an implementation subagent, explicitly ask to work in the
current thread, as in the example above.

## Install just this workflow

Use an up-to-date Codex client with skills and custom-agent support, signed into
your own account. Obtain a checkout of this dotfiles repository containing this
README, then run the following **from the repository root**:

```bash
engineer_codex_dir="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "$engineer_codex_dir/agents" "$engineer_codex_dir/skills/software-engineer/agents"
cp -i codex/agents/software-engineer.toml "$engineer_codex_dir/agents/"
cp -i codex/agents/software-engineer-guide.md "$engineer_codex_dir/agents/"
cp -i codex/skills/software-engineer/SKILL.md "$engineer_codex_dir/skills/software-engineer/"
cp -i codex/skills/software-engineer/agents/openai.yaml "$engineer_codex_dir/skills/software-engineer/agents/"
```

`cp -i` asks before replacing an existing file. Start a new conversation afterward;
restart Codex if the skill list has not refreshed. This installs at user scope,
making the workflow available across repositories on that machine.

These commands install only this workflow. The repository's full `install.sh`
and `codex-sync install` also restore the owner's other dotfile/Codex preferences;
teammates do not need to adopt those to use this agent.

## Open Code Review and costs

For substantial or high-risk changes, the engineer uses **Open Code Review
delegation mode** when installed. OCR supplies file selection and review rules;
the implementing Codex thread performs the review, addresses findings, and
reruns affected checks. It does not launch a separate reviewer by default.
Small changes receive a direct self-review.

To install the optional OCR integration:

```bash
npm install -g @alibaba-group/open-code-review@1.11.7
codex plugin marketplace add alibaba/open-code-review
codex plugin add open-code-review-codex@open-code-review
```

OCR requires Git 2.41 or later. Start a new Codex conversation after installing
the plugin. The engineer's instructions select delegation mode; no OCR LLM
endpoint needs configuring. If invoking the plugin directly outside the engineer
workflow, say `@Open Code Review use delegation mode to review my current changes`.

**Delegation is not free reasoning.** With subscription-authenticated Codex,
implementation and review consume your subscription allowance. No separate OCR
model API credentials are required. A Codex session authenticated through an API
uses that account's billing instead. Optional services, including hosted
Firecrawl, may charge or use their own credits. Token savings have not been measured.

## Optional tools

The agent uses tools already connected to your Codex session. Installing the
agent does not install these servers or copy anyone's credentials.

| Tool | When it helps |
| --- | --- |
| Serena | Find symbols, definitions, and callers without reading entire files. |
| Context7 or a dedicated docs MCP | Check version-sensitive library APIs. |
| Firecrawl | Research public documentation gaps with focused queries. |
| Project tests and browser/device tools | Verify behavior and visible UI changes. |
| Matt Pocock engineering skills | Apply test-first, debugging, or interface-design guidance when relevant. |

Optional tools have fallbacks: targeted local searches, existing project tests,
and explicit reporting of checks that could not run. Private code, client data,
and credentials should not be sent in public web queries.

[Matt Pocock's skills](https://github.com/mattpocock/skills),
[Serena](https://github.com/oraios/serena), and
[Aider](https://github.com/Aider-AI/aider) informed the approach.
[OpenHands](https://github.com/OpenHands/OpenHands) was researched as an option
for always-on orchestration. Aider and OpenHands are separate applications;
neither is embedded in this agent.

## What is ready, and what has been tested

The user-scope skill is discoverable by Codex. The custom role successfully
completed a disposable pagination fix: it reported three regression tests failing
before the fix, all five tests passed afterward, and an unrelated file was
preserved. Dotfiles restore tests cover the skill, agent, guide, and OCR settings.

This is a working setup with a small implementation smoke test, not an enterprise
reliability benchmark. That trial did not exercise every optional tool or a full
OCR review. Test it against your team's real tasks and retain your normal review
and CI requirements. It is not an unattended background service; it works when
invoked, within the session's permissions and requested scope.

Maintainers: [agent instructions](agents/software-engineer.toml),
[skill entry point](skills/software-engineer/SKILL.md), and
[design notes](agents/software-engineer-guide.md).
