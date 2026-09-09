import importlib.machinery
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "bin/claude-shared-skills"
loader = importlib.machinery.SourceFileLoader("claude_shared_skills", str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
shared = importlib.util.module_from_spec(spec)
loader.exec_module(shared)


class SharedSkillsTests(unittest.TestCase):
    def test_repairs_links_for_another_home_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as temp:
            root, home = Path(temp) / "repo", Path(temp) / "other-home"
            (root / "claude/skills").mkdir(parents=True)
            (root / "claude/external.json").write_text(json.dumps({
                "shared_skills": {"example/skills": ["present", "missing"]}}))
            source = home / ".agents/skills/present"
            source.mkdir(parents=True)
            (source / "SKILL.md").write_text("example")
            dest = root / "claude/skills/present"
            dest.symlink_to("../../.agents/skills/present")
            self.assertEqual(shared.restore(root, home), ["missing"])
            self.assertEqual(dest.resolve(), source.resolve())
            inode = dest.lstat().st_ino
            shared.restore(root, home)
            self.assertEqual(dest.lstat().st_ino, inode)
            dest.unlink()
            dest.mkdir()
            (dest / "local.txt").write_text("keep this")
            with self.assertRaises(FileExistsError):
                shared.restore(root, home)
            self.assertEqual((dest / "local.txt").read_text(), "keep this")


if __name__ == "__main__":
    unittest.main()
