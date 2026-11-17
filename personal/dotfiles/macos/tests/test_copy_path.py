import os
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest


SETUP_DIR = Path(__file__).resolve().parents[1]
WORKFLOW_CONTENTS = SETUP_DIR / "Copy Path.workflow" / "Contents"


def read_plist(name):
    with (WORKFLOW_CONTENTS / name).open("rb") as source:
        return plistlib.load(source)


class CopyPathWorkflowTests(unittest.TestCase):
    def test_service_is_scoped_to_finder_files_and_folders(self):
        service, = read_plist("Info.plist")["NSServices"]
        self.assertEqual(service["NSMenuItem"]["default"], "Copy Path")
        self.assertEqual(service["NSMessage"], "runWorkflowAsService")
        self.assertEqual(service["NSRequiredContext"]["NSApplicationIdentifier"], "com.apple.finder")
        self.assertEqual(service["NSSendFileTypes"], ["public.item"])

    def test_workflow_receives_paths_as_arguments_without_replacing_files(self):
        workflow = read_plist("document.wflow")
        action, = workflow["actions"]
        self.assertEqual(action["action"]["BundleIdentifier"], "com.apple.RunShellScript")
        self.assertEqual(action["action"]["ActionParameters"]["inputMethod"], 1)
        self.assertEqual(action["action"]["ActionParameters"]["shell"], "/bin/zsh")
        metadata = workflow["workflowMetaData"]
        self.assertEqual(metadata["workflowTypeIdentifier"], "com.apple.Automator.servicesMenu")
        self.assertEqual(metadata["serviceApplicationBundleID"], "com.apple.finder")
        self.assertEqual(metadata["serviceInputTypeIdentifier"], "com.apple.Automator.fileSystemObject")
        self.assertEqual(metadata["serviceOutputTypeIdentifier"], "com.apple.Automator.nothing")
        self.assertFalse(metadata["serviceProcessesInput"])


@unittest.skipUnless(Path("/bin/zsh").exists(), "The Quick Action uses macOS zsh")
class CopyPathScriptTests(unittest.TestCase):
    def run_script(self, paths, clipboard_body="cat"):
        return subprocess.run(
            [
                "/bin/zsh", "-df", "-c",
                'function /usr/bin/pbcopy { ' + clipboard_body + '; }; script=$1; shift; source "$script" "$@"',
                "copy-path-test", str(SETUP_DIR / "copy-path.sh"), *paths,
            ],
            capture_output=True,
            text=True,
            check=False,
        )

    def test_preserves_path_characters_and_multiple_selections(self):
        cases = [
            ["/Users/example/a file.txt"],
            ["/Users/example/folder", "/Users/example/second.txt"],
            ["/Users/example/廣東話.txt"],
            ["/Users/example/'quote' \"double\" \\slash $HOME $(exit 9) `exit 8` *.txt"],
            ["/Users/example/percent%s.txt", "/Users/example/line\nbreak.txt"],
        ]
        for paths in cases:
            with self.subTest(paths=paths):
                result = self.run_script(paths)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, "".join(path + "\n" for path in paths))

    def test_empty_selection_does_not_touch_clipboard(self):
        result = self.run_script([], "printf 'clipboard touched' >&2; return 1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "")

    def test_clipboard_failure_is_reported(self):
        result = self.run_script(["/Users/example/file.txt"], "return 7")
        self.assertEqual(result.returncode, 7)

    def test_workflow_command_reaches_script_and_preserves_arguments(self):
        command = read_plist("document.wflow")["actions"][0]["action"]["ActionParameters"]["COMMAND_STRING"]
        paths = ["/Users/example/a file.txt", "/Users/example/廣東話.txt"]
        with tempfile.TemporaryDirectory(prefix="tmp_rovo_copy_path_", dir=SETUP_DIR) as directory:
            home = Path(directory)
            dotfiles = home / "personal" / "dotfiles"
            dotfiles.mkdir(parents=True)
            (dotfiles / "macos").symlink_to(SETUP_DIR, target_is_directory=True)
            # Source the child script in this shell so the clipboard stub stays in place.
            wrapper = '''
function /usr/bin/pbcopy { cat; }
function /bin/zsh { local script=$1; shift; source "$script" "$@"; }
workflow_command=$1
shift
eval "$workflow_command"
'''
            result = subprocess.run(
                ["/bin/zsh", "-df", "-c", wrapper, "copy-path-test", command, *paths],
                env=os.environ | {"HOME": directory},
                capture_output=True,
                text=True,
                check=False,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "".join(path + "\n" for path in paths))


if __name__ == "__main__":
    unittest.main()
