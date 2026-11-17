import importlib.util
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


SETUP_DIR = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("docker_settings", SETUP_DIR / "docker-settings.py")
docker_settings = importlib.util.module_from_spec(spec)
spec.loader.exec_module(docker_settings)


class DockerSettingsTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="tmp_rovo_macos_", dir=SETUP_DIR)
        self.addCleanup(self.directory.cleanup)
        self.home = Path(self.directory.name)
        self.settings_path = self.home / docker_settings.DOCKER_SETTINGS_PATH
        self.preferences = self.home / "preferences.json"
        self.desired = {"Cpus": 12, "MemoryMiB": 8092}
        self.preferences.write_text(json.dumps(self.desired))

    def write_existing(self, settings):
        self.settings_path.parent.mkdir(parents=True, exist_ok=True)
        self.settings_path.write_text(json.dumps(settings))

    def run_main(self, *arguments):
        with (
            patch.object(Path, "home", return_value=self.home),
            patch.object(sys, "platform", "darwin"),
            patch.object(os, "geteuid", return_value=501),
            patch.object(sys, "argv", ["docker-settings.py", "--preferences", str(self.preferences), *arguments]),
        ):
            docker_settings.main()

    def test_merge_preserves_unmanaged_settings(self):
        self.write_existing({"Cpus": 4, "Unmanaged": {"keep": True}})
        self.assertEqual(
            docker_settings.pending_settings(self.settings_path, self.desired),
            self.desired | {"Unmanaged": {"keep": True}},
        )

    def test_missing_file_is_created_and_second_run_is_noop(self):
        with patch.object(docker_settings, "require_docker_stopped") as check:
            self.run_main()
            original = self.settings_path.read_bytes()
            self.run_main()
            check.assert_called_once()
        self.assertEqual(json.loads(original), self.desired)
        self.assertEqual(self.settings_path.read_bytes(), original)
        self.assertEqual(stat.S_IMODE(self.settings_path.stat().st_mode), 0o600)

    def test_check_does_not_write(self):
        with patch.object(docker_settings, "require_docker_stopped") as check:
            self.run_main("--check")
            check.assert_called_once()
        self.assertFalse(self.settings_path.parent.exists())

    def test_existing_permissions_are_preserved(self):
        self.write_existing({"Cpus": 4})
        self.settings_path.chmod(0o640)
        docker_settings.write_settings(self.settings_path, self.desired)
        self.assertEqual(stat.S_IMODE(self.settings_path.stat().st_mode), 0o640)
        self.assertEqual(list(self.settings_path.parent.glob("tmp_rovo_*")), [])

    def test_invalid_existing_json_is_not_overwritten(self):
        self.write_existing({})
        original = "invalid JSON"
        self.settings_path.write_text(original)
        with self.assertRaises(json.JSONDecodeError):
            self.run_main()
        self.assertEqual(self.settings_path.read_text(), original)

    def test_settings_must_be_objects(self):
        self.write_existing([])
        with self.assertRaises(ValueError):
            docker_settings.pending_settings(self.settings_path, self.desired)

    def test_running_docker_blocks_changes(self):
        self.write_existing({"Cpus": 4})
        original = self.settings_path.read_bytes()
        with patch.object(subprocess, "run", return_value=subprocess.CompletedProcess([], 0)):
            with self.assertRaisesRegex(RuntimeError, "Quit Docker"):
                self.run_main()
        self.assertEqual(self.settings_path.read_bytes(), original)

    def test_unchanged_settings_do_not_require_docker_to_stop(self):
        self.write_existing(self.desired)
        with patch.object(docker_settings, "require_docker_stopped") as check:
            self.run_main()
            check.assert_not_called()

    def test_process_check_errors_are_not_treated_as_stopped(self):
        with patch.object(subprocess, "run", return_value=subprocess.CompletedProcess([], 2)):
            with self.assertRaises(subprocess.CalledProcessError):
                docker_settings.require_docker_stopped()

    def test_stopped_docker_is_accepted(self):
        with patch.object(subprocess, "run", return_value=subprocess.CompletedProcess([], 1)):
            docker_settings.require_docker_stopped()

    def test_failed_replace_keeps_original_and_cleans_temporary_file(self):
        self.write_existing({"Cpus": 4})
        original = self.settings_path.read_bytes()
        with patch.object(Path, "replace", side_effect=OSError("replace failed")):
            with self.assertRaises(OSError):
                docker_settings.write_settings(self.settings_path, self.desired)
        self.assertEqual(self.settings_path.read_bytes(), original)
        self.assertEqual(list(self.settings_path.parent.glob("tmp_rovo_*")), [])

    def test_refuses_other_platforms_and_root(self):
        for platform, uid in [("linux", 501), ("darwin", 0)]:
            with (
                self.subTest(platform=platform, uid=uid),
                patch.object(sys, "platform", platform),
                patch.object(os, "geteuid", return_value=uid),
                patch.object(sys, "argv", ["docker-settings.py"]),
                self.assertRaises(RuntimeError),
            ):
                docker_settings.main()


class ShellSettingsTests(unittest.TestCase):
    def run_script(self, script, functions):
        return subprocess.run(
            ["bash", "-c", functions + '\nsource "$1"', "test", str(SETUP_DIR / script)],
            capture_output=True,
            text=True,
            check=False,
        )

    @unittest.skipIf(os.geteuid() == 0, "Mouse defaults deliberately refuse root")
    def test_mouse_defaults_only_call_expected_commands(self):
        result = self.run_script("mouse-defaults.sh", '''
uname() { printf 'Darwin\\n'; }
defaults() { printf '%s|' "$@"; printf '\\n'; }
''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines()[:-1], [
            "write|NSGlobalDomain|com.apple.mouse.linear|-bool|true|",
            "write|NSGlobalDomain|com.apple.mouse.scaling|-float|1.5|",
            "write|NSGlobalDomain|com.apple.trackpad.scaling|-float|3|",
            "write|NSGlobalDomain|com.apple.swipescrolldirection|-bool|true|",
            "write|com.pilotmoon.scroll-reverser|InvertScrollingOn|-bool|true|",
            "write|com.pilotmoon.scroll-reverser|ReverseTrackpad|-bool|false|",
        ])

    def test_mouse_defaults_refuse_other_platforms(self):
        result = self.run_script("mouse-defaults.sh", "uname() { printf 'Linux\\n'; }")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("only supported on macOS", result.stderr)

    def test_display_sleep_only_changes_display_timers(self):
        result = self.run_script("display-sleep.sh", "pmset() { printf '%s|' \"$@\"; printf '\\n'; }")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), ["-b|displaysleep|2|", "-c|displaysleep|60|"])

    def test_rebuild_preferences_exclude_mouse_and_scrolling(self):
        preferences = json.loads((SETUP_DIR / "preferences.json").read_text())
        self.assertNotIn("com.pilotmoon.scroll-reverser", preferences)
        self.assertFalse(any(
            key.startswith(("com.apple.mouse", "com.apple.trackpad", "com.apple.swipescrolldirection"))
            for key in preferences["NSGlobalDomain"]
        ))


if __name__ == "__main__":
    unittest.main()
