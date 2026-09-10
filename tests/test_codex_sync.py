import copy
import importlib.machinery
import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import tomllib
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "bin" / "codex-sync"
loader = importlib.machinery.SourceFileLoader("codex_sync", str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
sync = importlib.util.module_from_spec(spec)
loader.exec_module(sync)


class CodexSyncTests(unittest.TestCase):
    def test_export_excludes_credentials_and_machine_state(self):
        source = {
            "model": "example", "web_search": "disabled",
            "projects": {"private-project": {"trust_level": "trusted"}},
            "hooks": {"state": "machine-specific"},
            "notify": ["/Users/example/.codex/computer-use/Runtime.app/client", "turn-ended"],
            "mcp_servers": {
                "firecrawl": {"url": "https://mcp.firecrawl.dev/v2/mcp-oauth"},
                "secret": {"env": {"API_KEY": "test-secret"}},
                "header": {"http_headers": {"Authorization": "test-secret"}},
                "query": {"url": "https://example.com/?token=test-secret"},
                "login": {"url": "https://user:test-secret@example.com/"},
                "bearer": {"url": "https://example.com/", "bearer_token": "test-secret"},
                "node_repl": {"command": "/Applications/local-runtime"},
            },
            "marketplaces": {
                "example": {"source_type": "git", "source": "https://github.com/example/skills"},
                "runtime": {"source_type": "local", "source": "/private/cache"},
            },
            "plugins": {"example@example": {"enabled": True}, "app@runtime": {"enabled": True}},
        }
        result = sync.capture(source)
        self.assertEqual(set(result["mcp_servers"]), {"firecrawl"})
        self.assertEqual(set(result["plugins"]), {"example@example"})
        for key in ("projects", "hooks", "notify"):
            self.assertNotIn(key, result)
        self.assertEqual(result["web_search"], "disabled")
        self.assertNotIn("test-secret", sync.dumps(result))

    def test_export_retains_preferences_without_hook_trust_or_onboarding(self):
        source = {
            "developer_instructions": "Follow the project conventions.",
            "tui": {"status_line": ["git-branch"], "model_availability_nux": {"example": 4}},
            "apps": {"example": {"tools": {"read": {"approval_mode": "prompt"}}}},
            "notify": ["/home/example/bin/notify", "done"],
            "hooks": {
                "state": {"local-hook": {"trusted_hash": "machine-specific"}},
                "Stop": [{"hooks": [{"type": "command", "command": "echo done"}]}],
            },
        }
        result = sync.capture(source)
        for key in ("developer_instructions", "apps", "notify"):
            self.assertEqual(result[key], source[key])
        self.assertEqual(result["tui"], {"status_line": ["git-branch"]})
        self.assertEqual(result["hooks"], {"Stop": source["hooks"]["Stop"]})
        self.assertEqual(tomllib.loads(sync.dumps(result)), result)
        self.assertIn("state", source["hooks"])

    def test_restore_preserves_local_state_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as temp:
            live = Path(temp)
            before = {
                "model": "old", "projects": {"private-project": {"trust_level": "trusted"}},
                "mcp_servers": {
                    "private": {"env": {"API_KEY": "test-secret"}},
                    "graphify": {"url": "https://api.graphify.com/mcp"},
                    "node_repl": {"command": "/Applications/local-runtime"},
                },
            }
            original = sync.dumps(before)
            (live / "config.toml").write_text(original)
            (live / "AGENTS.md").write_text("existing instructions\n")
            (live / "auth.json").write_text("untouched credentials\n")
            command = [sys.executable, str(SCRIPT), "install", "--codex-home", str(live)]
            subprocess.run(command, check=True, capture_output=True)
            restored = tomllib.loads((live / "config.toml").read_text())
            self.assertEqual(restored["projects"], before["projects"])
            self.assertEqual(restored["mcp_servers"]["private"], before["mcp_servers"]["private"])
            self.assertEqual(restored["mcp_servers"]["node_repl"], before["mcp_servers"]["node_repl"])
            self.assertNotIn("graphify", restored["mcp_servers"])
            self.assertEqual(restored["web_search"], "disabled")
            self.assertIn("firecrawl", restored["mcp_servers"])
            self.assertEqual((live / "auth.json").read_text(), "untouched credentials\n")
            backups = list((live / "dotfiles-backups").iterdir())
            self.assertEqual((backups[0] / "config.toml").read_text(), original)
            self.assertEqual((backups[0] / "AGENTS.md").read_text(), "existing instructions\n")
            self.assertEqual((live / "config.toml").stat().st_mode & 0o777, 0o600)
            first = (live / "config.toml").read_bytes()
            subprocess.run(command, check=True, capture_output=True)
            self.assertEqual((live / "config.toml").read_bytes(), first)
            self.assertEqual(list((live / "dotfiles-backups").iterdir()), backups)

    def test_fresh_restore_and_portability(self):
        with tempfile.TemporaryDirectory() as temp:
            live = Path(temp) / "new-codex"
            subprocess.run([sys.executable, str(SCRIPT), "install", "--codex-home", str(live)],
                           check=True, capture_output=True)
            restored = tomllib.loads((live / "config.toml").read_text())
            self.assertIn("firecrawl", restored["mcp_servers"])
            self.assertTrue((live / "skills/worktree/SKILL.md").exists())
            self.assertTrue((live / "skills/worktree-cleanup/references/docker.md").exists())
            self.assertTrue((live / "skills/ics-jira-dev-ready/SKILL.md").exists())
            skill = live / "skills/software-engineer/SKILL.md"
            self.assertTrue(skill.exists())
            self.assertTrue((skill.parent / "agents/openai.yaml").exists())
            self.assertEqual((skill.parent / "../../agents/software-engineer.toml").resolve(),
                             (live / "agents/software-engineer.toml").resolve())
            self.assertEqual(len(list((live / "agents").glob("*.toml"))), 4)
            engineer = live / "agents/software-engineer.toml"
            self.assertEqual(tomllib.loads(engineer.read_text())["name"], "software_engineer")
            self.assertEqual((live / "agents/software-engineer-guide.md").read_bytes(),
                             (SCRIPT.parent.parent / "codex/agents/software-engineer-guide.md").read_bytes())
            self.assertTrue(restored["plugins"]["open-code-review-codex@open-code-review"]["enabled"])
            self.assertEqual(restored["marketplaces"]["open-code-review"]["source"],
                             "https://github.com/alibaba/open-code-review.git")
            self.assertIn("open-code-review-delegate", (live / "AGENTS.md").read_text())
            self.assertNotIn("{{HOME}}", (live / "config.toml").read_text())
            portable = sync.portable(copy.deepcopy(restored), Path.home())
            self.assertEqual(sync.portable(portable, Path.home(), restore=True), restored)


if __name__ == "__main__":
    unittest.main()
