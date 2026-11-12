"""Request the system browser without claiming that the page has loaded."""

import os
import platform
import subprocess
from urllib.parse import urlsplit

OPEN_TIMEOUT_SECONDS = 10


def result(status, method, detail):
    return {"event": "browser_launch", "status": status, "method": method, "detail": detail}


def launch_browser(url):
    if urlsplit(url).scheme not in {"http", "https"}:
        return result("failed", "none", "Expected an HTTP or HTTPS URL")
    system = platform.system()
    if system == "Windows":
        try:
            os.startfile(url)
        except OSError as error:
            return result("failed", "startfile", str(error))
        return result("requested", "startfile", "OS accepted the request; page load is not confirmed")
    # Use the desktop's URL association, not Python's BROWSER override or AppleScript automation.
    commands = {"Darwin": [("/usr/bin/open",)], "Linux": [("xdg-open",), ("gio", "open")]}.get(system)
    if commands is None:
        return result("failed", "none", f"Unsupported platform: {system}")
    for command in commands:
        method = " ".join(command)
        try:
            completed = subprocess.run([*command, url], capture_output=True, text=True, timeout=OPEN_TIMEOUT_SECONDS, check=False)
        except FileNotFoundError:
            continue
        except subprocess.TimeoutExpired:
            return result("failed", method, "Opener timed out; it may still have handed off the URL. Check the browser before retrying.")
        except OSError as error:
            return result("failed", method, str(error))
        if completed.returncode != 0:
            return result("failed", method, completed.stderr.strip() or f"Opener exited with status {completed.returncode}")
        return result("requested", method, "OS accepted the request; page load is not confirmed")
    return result("failed", "none", "No desktop URL opener found; open the printed URL manually")
