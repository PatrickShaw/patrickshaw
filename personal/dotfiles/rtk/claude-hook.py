"""Keep RTK's automatic rewriting away from machine-readable shell output."""

import json
import re
import shlex
import subprocess
import sys


MAX_INPUT_BYTES = 1024 * 1024
AUTO_COMMANDS = frozenset({
    ("git", "status"),
    ("git", "log"),
    ("git", "diff", "--stat"),
    ("cargo", "test"),
    ("cargo", "check"),
    ("cargo", "build"),
    ("cargo", "clippy"),
    ("npm", "test"),
    ("pnpm", "test"),
    ("bun", "test"),
    ("pytest",),
    ("go", "test", "./..."),
})


def should_rewrite(payload):
    if not isinstance(payload, dict) or payload.get("tool_name") != "Bash":
        return False
    tool_input = payload.get("tool_input")
    if not isinstance(tool_input, dict):
        return False
    command = tool_input.get("command")
    if not isinstance(command, str) or any(char in command for char in "\n\r$`"):
        return False
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
        lexer.whitespace_split = True
        lexer.commenters = ""
        words = tuple(lexer)
    except ValueError:
        return False

    # Additional flags may request a stable output format. Opt in explicitly
    # with `rtk ...` rather than guessing which flags are safe to summarise.
    return words in AUTO_COMMANDS or (
        len(words) == 3
        and words[:2] == ("git", "log")
        and re.fullmatch(r"-[1-9][0-9]*", words[2]) is not None
    )


def main():
    raw = sys.stdin.buffer.read(MAX_INPUT_BYTES + 1)
    if len(raw) > MAX_INPUT_BYTES:
        print("RTK hook input too large; leaving the command unchanged", file=sys.stderr)
        return 0
    try:
        payload = json.loads(raw)
    except (ValueError, UnicodeDecodeError):
        print("Invalid RTK hook input; leaving the command unchanged", file=sys.stderr)
        return 0
    if not should_rewrite(payload):
        return 0
    return subprocess.run(["rtk", "hook", "claude"], input=raw, check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
