import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch
import io


spec = importlib.util.spec_from_file_location("claude_hook", Path(__file__).with_name("claude-hook.py"))
hook = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hook)


class ClaudeHookTests(unittest.TestCase):
    def allows(self, command):
        return hook.should_rewrite({"tool_name": "Bash", "tool_input": {"command": command}})

    def test_simple_human_readable_commands(self):
        for command in ["git status", "git log", "git log -20", "git diff --stat", "cargo test",
                        "cargo check", "cargo build", "cargo clippy", "npm test", "pnpm test",
                        "bun test", "pytest", "go test ./...", "  git   status  ", "git 'status'"]:
            with self.subTest(command=command):
                self.assertTrue(self.allows(command))

    def test_flags_and_structured_output_are_not_guessed(self):
        for command in ["git status --porcelain", "git status -z", "git status --short",
                        "git diff --numstat", "git log --format=%H", "rg --json needle .",
                        "cargo test --message-format=json", "npm test -- --json", "pytest --json-report",
                        "git log -5 --format=%H", "gh api user", "curl https://example.com"]:
            with self.subTest(command=command):
                self.assertFalse(self.allows(command))

    def test_shell_composition_and_expansion_are_untouched(self):
        for command in ["git status | cat", "git status && git log", "git status; git log",
                        "git status > status.txt", "git status 2>&1", "git status &", "(git status)",
                        "git status\ngit log", "git status\n", "git status\r", "git $ACTION",
                        "git `echo status`", "git $(echo status)", "git status # comment",
                        "RTK_DISABLED=1 git status", "cd repo && git status", "git 'status"]:
            with self.subTest(command=command):
                self.assertFalse(self.allows(command))

    def test_existing_wrappers_and_unknown_commands_are_untouched(self):
        for command in ["rtk git status", "rtk bypass git status", "env git status", "/usr/bin/git status",
                        "git push", "git commit", "python3 -m pytest", "printf hello", "", "git log -0"]:
            with self.subTest(command=command):
                self.assertFalse(self.allows(command))

    def test_other_tools_and_malformed_payloads_are_untouched(self):
        for payload in [None, [], {}, {"tool_name": "Read"},
                        {"tool_name": "Bash", "tool_input": None},
                        {"tool_name": "Bash", "tool_input": {"command": 42}}]:
            with self.subTest(payload=payload):
                self.assertFalse(hook.should_rewrite(payload))

    def test_forwards_exact_payload_to_native_hook(self):
        raw = b'{"tool_name":"Bash","tool_input":{"command":"git status","timeout":42}}'
        with patch.object(hook.sys, "stdin") as stdin, patch.object(hook.subprocess, "run") as run:
            stdin.buffer = io.BytesIO(raw)
            run.return_value.returncode = 0
            self.assertEqual(hook.main(), 0)
            run.assert_called_once_with(["rtk", "hook", "claude"], input=raw, check=False)

    def test_machine_output_does_not_invoke_rtk(self):
        raw = b'{"tool_name":"Bash","tool_input":{"command":"git status --porcelain"}}'
        with patch.object(hook.sys, "stdin") as stdin, patch.object(hook.subprocess, "run") as run:
            stdin.buffer = io.BytesIO(raw)
            self.assertEqual(hook.main(), 0)
            run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
