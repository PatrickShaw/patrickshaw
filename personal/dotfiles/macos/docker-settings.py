#!/usr/bin/env python3

import argparse
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile


DOCKER_SETTINGS_PATH = Path("Library/Group Containers/group.com.docker/settings-store.json")
OWNER_READ_WRITE = stat.S_IRUSR | stat.S_IWUSR


def pending_settings(settings_path, desired):
    existing = json.loads(settings_path.read_text()) if settings_path.exists() else {}
    if not isinstance(existing, dict) or not isinstance(desired, dict):
        raise ValueError("Docker settings must be JSON objects")
    merged = existing | desired
    return merged if merged != existing else None


def require_docker_stopped():
    result = subprocess.run(
        ["/usr/bin/pgrep", "-f", "/Docker[.]app/Contents/"],
        capture_output=True,
        check=False,
    )
    if result.returncode == 0:
        raise RuntimeError("Quit Docker Desktop before applying its settings or rebuilding")
    if result.returncode != 1:
        result.check_returncode()


def write_settings(settings_path, settings):
    settings_path.parent.mkdir(parents=True, exist_ok=True)
    mode = stat.S_IMODE(settings_path.stat().st_mode) if settings_path.exists() else OWNER_READ_WRITE
    temporary_path = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", dir=settings_path.parent, prefix="tmp_rovo_docker_", delete=False
        ) as temporary:
            temporary_path = Path(temporary.name)
            json.dump(settings, temporary, indent=2)
            temporary.write("\n")
        temporary_path.chmod(mode)
        temporary_path.replace(settings_path)
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description="Merge declared Docker Desktop preferences")
    parser.add_argument("--check", action="store_true", help="Validate without writing")
    parser.add_argument("--preferences", type=Path, default=Path(__file__).with_name("docker-settings.json"))
    args = parser.parse_args()

    if sys.platform != "darwin" or os.geteuid() == 0:
        raise RuntimeError("Run this on macOS as your normal user, without sudo")

    settings_path = Path.home() / DOCKER_SETTINGS_PATH
    desired = json.loads(args.preferences.read_text())
    settings = pending_settings(settings_path, desired)
    if settings is None:
        print("Docker Desktop preferences already match")
        return

    # Docker writes this file itself. Don't race it or replace unrelated settings.
    require_docker_stopped()
    if args.check:
        print("Docker Desktop preferences can be applied")
    else:
        write_settings(settings_path, settings)
        print("Docker Desktop preferences updated")


if __name__ == "__main__":
    main()
