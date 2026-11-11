# /// script
# # WARNING: Newer Pythons than PyYAML ships wheels for get a pure Python build
# # without CLoader, which Camoufox imports. So keep this in step with the
# # `python` in camoufox.nix
# requires-python = "==3.13.*"
# dependencies = [
#     # WARNING: @playwright/mcp only works against this when it bundles the
#     # same Playwright minor version. Bump the `camoufox` MCP entry in
#     # private/dotfiles/agents/rovo/mcp.json alongside this. See the camoufox
#     # skill for how to find a matching pair.
#     "camoufox[geoip]==0.5.9",
#     "playwright==1.62.0",
# ]
# ///
"""Keeps a headed Camoufox running with a persistent profile so agents can drive it through @playwright/mcp."""
import sys

from camoufox.sync_api import Camoufox

# @playwright/mcp finds the browser by this title (`--endpoint camoufox`), so
# there's no port or random websocket path to keep in sync.
BIND_TITLE = "camoufox"

# Claiming the real OS means Camoufox doesn't need canvas/WebGL noise to hide
# it, which otherwise makes us look like Tor/LibreWolf rather than stock Firefox.
HOST_OS = "macos"

WAIT_FOREVER = 0


def main(profile_dir: str) -> None:
    # Persistent context rather than `camoufox server` because the latter
    # refuses user_data_dir, which is the only way logins survive a restart
    with Camoufox(
        headless=False,
        os=HOST_OS,
        persistent_context=True,
        user_data_dir=profile_dir,
    ) as context:
        # No host/port on purpose - a websocket bind gets pruned from
        # Playwright's server registry by newer clients, a pipe doesn't
        context.browser.bind(BIND_TITLE)
        # Returning (rather than blocking forever) means quitting the window
        # is a clean exit, so launchd only restarts us after a crash
        context.wait_for_event("close", timeout=WAIT_FOREVER)


if __name__ == "__main__":
    main(profile_dir=sys.argv[1])
