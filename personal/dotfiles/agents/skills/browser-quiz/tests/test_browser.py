import importlib.util
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("quiz_browser", Path(__file__).resolve().parents[1] / "scripts" / "browser.py")
browser = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(browser)
URL = "http://[::1]:8000/test/"


class BrowserTests(unittest.TestCase):
    def test_mac_uses_native_opener_and_does_not_claim_page_loaded(self):
        with patch.object(browser.platform, "system", return_value="Darwin"), patch.object(browser.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, "", "")) as run:
            result = browser.launch_browser(URL)
        self.assertEqual(result["status"], "requested")
        self.assertIn("not confirmed", result["detail"])
        self.assertEqual(run.call_args.args[0], ["/usr/bin/open", URL])
        self.assertEqual(run.call_args.kwargs["timeout"], browser.OPEN_TIMEOUT_SECONDS)
        self.assertNotIn("shell", run.call_args.kwargs)

    def test_failure_includes_stderr(self):
        with patch.object(browser.platform, "system", return_value="Darwin"), patch.object(browser.subprocess, "run", return_value=subprocess.CompletedProcess([], 1, "", "No application associated")):
            self.assertEqual(browser.launch_browser(URL)["detail"], "No application associated")

    def test_timeout_does_not_invent_a_cause(self):
        with patch.object(browser.platform, "system", return_value="Darwin"), patch.object(browser.subprocess, "run", side_effect=subprocess.TimeoutExpired("open", 10)):
            result = browser.launch_browser(URL)
        self.assertEqual(result["status"], "failed")
        self.assertIn("timed out", result["detail"])
        self.assertNotIn("permission", result["detail"])

    def test_permission_error_reported(self):
        with patch.object(browser.platform, "system", return_value="Darwin"), patch.object(browser.subprocess, "run", side_effect=PermissionError("denied")):
            self.assertEqual(browser.launch_browser(URL)["detail"], "denied")

    def test_linux_gio_when_xdg_open_missing(self):
        with patch.object(browser.platform, "system", return_value="Linux"), patch.object(browser.subprocess, "run", side_effect=[FileNotFoundError(), subprocess.CompletedProcess([], 0)]) as run:
            result = browser.launch_browser(URL)
        self.assertEqual(result["status"], "requested")
        self.assertEqual(run.call_args.args[0], ["gio", "open", URL])

    def test_missing_openers(self):
        with patch.object(browser.platform, "system", return_value="Linux"), patch.object(browser.subprocess, "run", side_effect=FileNotFoundError()):
            self.assertEqual(browser.launch_browser(URL)["status"], "failed")

    def test_windows_success_and_failure(self):
        with patch.object(browser.platform, "system", return_value="Windows"), patch.object(browser.os, "startfile", create=True) as startfile:
            self.assertEqual(browser.launch_browser(URL)["status"], "requested")
            startfile.assert_called_once_with(URL)
            startfile.side_effect = OSError("no association")
            self.assertEqual(browser.launch_browser(URL)["status"], "failed")

    def test_unsupported_platform(self):
        with patch.object(browser.platform, "system", return_value="unsupported"):
            self.assertEqual(browser.launch_browser(URL)["status"], "failed")

    def test_non_web_urls_rejected(self):
        with patch.object(browser.subprocess, "run") as run:
            self.assertEqual(browser.launch_browser("file:///secret")["status"], "failed")
            run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
