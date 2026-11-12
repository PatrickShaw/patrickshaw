import json
import logging
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import refresh


class RefreshTests(unittest.TestCase):
    def test_launcher_reuses_pins_store_and_privacy_settings(self):
        with tempfile.TemporaryDirectory(prefix="tmp_rovo_grounded_test_", dir=Path.cwd()) as directory:
            path = Path(directory) / "mcp.json"
            path.write_text(json.dumps({"mcpServers": {"grounded": {
                "command": "npx",
                "args": ["-y", "--package=node@24", "--package=@arabold/docs-mcp-server@3", "docs-mcp-server", "--protocol", "stdio", "--store-path", "/example/store", "--no-telemetry", "--embedding-model", "openai:text-embedding-3-small"],
                "env": {"OPENAI_API_KEY": "must-not-be-used", "DOCS_MCP_SCRAPER_MAX_CONCURRENCY": "2"},
            }}}))
            prefix, options, environment = refresh.cli_from_mcp(path)
            self.assertEqual(prefix, ["npx", "-y", "--package=node@24", "--package=@arabold/docs-mcp-server@3", "docs-mcp-server"])
            self.assertEqual(options, ["--store-path", "/example/store", "--no-telemetry"])
            self.assertEqual(environment["OPENAI_API_KEY"], "")
            self.assertEqual(environment["DOCS_MCP_APP_TELEMETRY_ENABLED"], "false")
            self.assertEqual(environment["DOCS_MCP_APP_EMBEDDING_MODEL"], "openai:text-embedding-3-small")
            self.assertEqual(environment["DOCS_MCP_SCRAPER_MAX_CONCURRENCY"], "2")

    def test_enumerates_every_version_including_rolling_and_spaces(self):
        libraries = [{"name": "Library with spaces", "versions": [
            {"version": "", "status": "completed", "sourceUrl": "https://example.com/latest"},
            {"version": "1.0", "status": "failed", "sourceUrl": "https://example.com/v1"},
        ]}]
        targets = list(refresh.refresh_targets(libraries))
        calls = []

        def execute(arguments, timeout):
            calls.append((arguments, timeout))
            return "refreshed"

        results = refresh.refresh_all(targets, execute, logging.getLogger("test"))
        self.assertEqual([call[0] for call in calls], [
            ["refresh", "Library with spaces", "--version", ""],
            ["refresh", "Library with spaces", "--version", "1.0"],
        ])
        self.assertTrue(all(result["result"] == "refreshed" for result in results))

    def test_skips_active_or_unsourced_and_continues_after_failure(self):
        targets = [
            {"library": status, "version": "", "status": status, "source": "https://example.com"}
            for status in ["running", "queued", "failed", "completed"]
        ] + [{"library": "local", "version": "", "status": "completed", "source": None}]
        calls = []

        def execute(arguments, timeout):
            calls.append(arguments)
            if arguments[1] == "failed":
                raise subprocess.TimeoutExpired(arguments, timeout)
            return "refreshed"

        with self.assertLogs("test", level="INFO"):
            results = refresh.refresh_all(targets, execute, logging.getLogger("test"))
        self.assertEqual([r["result"] for r in results], ["skipped-active", "skipped-active", "failed", "refreshed", "skipped-no-source"])
        self.assertEqual(len(calls), 2)

    def test_command_errors_and_timeouts_are_reported(self):
        with self.assertRaisesRegex(RuntimeError, "Command exited 7"):
            refresh.run_command([sys.executable, "-c", "raise SystemExit(7)"], os.environ.copy(), 5)
        with self.assertRaises(subprocess.TimeoutExpired):
            refresh.run_command([sys.executable, "-c", "import time; time.sleep(30)"], os.environ.copy(), 0.1)

    def test_termination_enters_child_cleanup_path(self):
        with self.assertRaises(KeyboardInterrupt):
            refresh.stop_requested(None, None)

    def test_empty_index_does_not_run_any_refresh(self):
        def unexpected(arguments, timeout):
            self.fail("No command should run for an empty index")

        self.assertEqual(refresh.refresh_all([], unexpected, logging.getLogger("test")), [])

    def test_lock_prevents_overlap_and_releases(self):
        with tempfile.TemporaryDirectory(prefix="tmp_rovo_grounded_test_", dir=Path.cwd()) as directory:
            path = Path(directory) / "run.lock"
            with refresh.run_lock(path) as first:
                self.assertTrue(first)
                with refresh.run_lock(path) as second:
                    self.assertFalse(second)
            with refresh.run_lock(path) as third:
                self.assertTrue(third)


if __name__ == "__main__":
    unittest.main()
