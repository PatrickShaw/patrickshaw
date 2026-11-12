# Grounded refresh

Refreshes every indexed library and version each Sunday at 10:00 local time on macOS. New libraries are picked up automatically; there's no fixed list and no LLM call.

The Home Manager job lives in `../nix/shared/home-manager/modules/services.nix`. It uses the pinned launcher, environment and store settings from `~/.rovo/mcp.json`, with telemetry off and the OpenAI embedding key cleared. Keep that MCP entry in stdio/npx form while this runner uses it.

Versions refresh one at a time, retaining their saved source URLs and crawl limits. Active indexing jobs are skipped. A failed refresh is recorded and the remaining libraries still run; the overall job exits unsuccessfully if any version fails. Each version has a 15-minute timeout. An advisory lock prevents overlapping scheduled or manual runs.

launchd catches a calendar trigger missed during sleep when the Mac wakes. It doesn't wake the laptop, run while powered off, or guarantee a catch-up after shutdown. Network failures are logged and retried at the next scheduled run; there is no automatic retry loop.

## Inspect or run it

```sh
python3 ~/.config/grounded-refresh/refresh.py --dry-run
python3 ~/.config/grounded-refresh/refresh.py
launchctl print "gui/$(id -u)/org.nix-community.home.grounded-refresh"
```

`~/.local/state/grounded-refresh/latest.log` and `latest.json` describe the most recent run. launchd startup output is in `~/Library/Logs/grounded-refresh.log` and `grounded-refresh.error.log`. No login-triggered refresh runs when the agent is loaded.

This updates existing sources, not the versions you track. Adding a new major release is a separate indexing request. Rolling documentation stays rolling.

## Tests

From this directory:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest -v
```

Tests use synthetic inputs and temporary directories under the current directory. They don't crawl documentation or change the live index.
