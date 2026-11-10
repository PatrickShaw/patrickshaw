---
name: camoufox
description: How Patrick's long-running Camoufox (anti-detect Firefox) is set up and driven through the `camoufox` Playwright MCP server. Load before browsing with Camoufox, when the camoufox MCP tools fail to connect, or before changing or upgrading anything Camoufox related.
---

# Camoufox

Camoufox is a patched Firefox that hides automation and spoofs its fingerprint. Patrick keeps one running at all times, **headed** (a real visible window, never headless) so he can watch what it's doing and step in to log into things. Agents drive it with the `camoufox` MCP server, which is plain `@playwright/mcp` pointed at that running browser.

**Use the `camoufox` MCP tools. Don't write Python/Playwright scripts to drive Camoufox** - the whole point of this setup is to avoid spending tokens on throwaway scripts.

## How do the pieces fit together?

1. `~/personal/dotfiles/camoufox/server.py` launches Camoufox headed, with a persistent profile, and calls Playwright's `browser.bind("camoufox")`. Its dependencies are pinned inline (PEP 723) and run with `uv run --script`.
2. `~/personal/dotfiles/nix/shared/home-manager/modules/camoufox.nix` runs that script as a launchd agent at login. The profile lives in `~/.local/share/camoufox/profile`.
3. `bind()` registers the browser in Playwright's server registry (`~/Library/Caches/ms-playwright/b/`) under the title `camoufox`.
4. The `camoufox` entry in `~/me/private/dotfiles/agents/rovo/mcp.json` runs `@playwright/mcp --endpoint camoufox`. It looks the browser up by that title, so there's no port or websocket URL to keep in sync.

The MCP reuses the browser's persistent context rather than making a fresh one, so cookies and logins survive restarts. Session-only cookies (no expiry) still disappear on restart, same as any browser.

## Is it running?

```sh
launchctl print "gui/$(id -u)/org.nix-community.home.camoufox" | grep -E 'state|pid'
ls ~/Library/Caches/ms-playwright/b/
tail ~/Library/Logs/camoufox.error.log
```

Quitting the Camoufox window is a clean exit and launchd leaves it stopped. Only crashes restart it. To bring it back:

```sh
launchctl kickstart "gui/$(id -u)/org.nix-community.home.camoufox"
```

Only one Camoufox can use the profile at a time (Firefox locks it), so don't launch a second copy against the same profile.

## How do I upgrade it?

The Camoufox side and the MCP side **must bundle the same Playwright minor version**. Otherwise the MCP fails with `Playwright version mismatch`. Playwright's "connect across versions" path half works (`browser_evaluate` ran but `browser_navigate` failed with `Cannot read properties of undefined (reading 'tools')`), so don't rely on it.

1. Check the newest Camoufox and what Playwright it allows: `curl -s https://pypi.org/pypi/camoufox/json | jq -r '.info.version, (.info.requires_dist[] | select(startswith("playwright")))'`
2. Find the newest `@playwright/mcp` bundling that Playwright minor: `npm view @playwright/mcp@<version> dependencies.playwright-core`
3. Bump `camoufox` and `playwright` in the `server.py` header, and the `@playwright/mcp@...` version in both `mcp.json` and the `allowedMcpServers` list in `~/me/private/dotfiles/agents/rovo/config.yml`.
4. `launchctl kickstart -k "gui/$(id -u)/org.nix-community.home.camoufox"`, then restart the agent harness so it picks up the new MCP version.

On a fresh machine the browser binary may also need fetching once: `uvx --from 'camoufox[geoip]==<version>' camoufox fetch`.

## Gotchas

- Don't point `@playwright/mcp --browser firefox --executable-path` at the Camoufox binary. That skips the Python wrapper, which is where the fingerprint gets generated.
- `camoufox server` (Camoufox's own server mode) refuses `persistent_context`/`user_data_dir`, which is why we use `bind()` instead.
- Bind without a host/port. A websocket bind gets deleted from the registry by newer Playwright clients that can't health-check it. A pipe bind doesn't.
- `os="macos"` is deliberate. When the spoofed OS doesn't match the real one, Camoufox adds canvas/WebGL noise, which makes it read as a privacy-hardened Firefox (Tor/LibreWolf) rather than stock Firefox. Other fingerprint details are still regenerated on every launch.
