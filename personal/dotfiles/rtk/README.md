# RTK

Local command-output filtering for coding agents. The shared Home Manager module installs the nixpkgs-pinned RTK with default features disabled, excluding the BUSL pipeline engine. No proxy, model calls or third-party pipelines.

## How is it wired up?

- `../nix/shared/home-manager/modules/rtk.nix` installs the CLI on macOS and Linux, disables telemetry and links this config out of store.
- macOS config: `~/Library/Application Support/rtk/config.toml`.
- Linux config: `$XDG_CONFIG_HOME/rtk/config.toml` (normally `~/.config/rtk/config.toml`).
- Shared agent guidance asks Rovo and Codex to use RTK explicitly for supported verbose commands. This is model guidance, not automatic interception.
- The private Claude settings call `rtk-claude-hook` for Bash calls, retaining existing hooks. Home Manager packages that wrapper with Python and RTK on its PATH. It passes through until the wrapper is installed. No broad RTK permission allowlist is added.
- `claude-hook.py` forwards only a small set of simple, human-readable commands to the native `rtk hook claude`. Other flags, pipelines, redirects and compound commands stay unchanged. This is deliberate: 1.1.0 rewrites `git status --porcelain` even though its output is not byte-identical. Add automatic coverage only with regression tests.
- The stale Rovo `on_tool_start` shell-hook entry is removed. Command rewriting through that event has not been verified; don't install a Claude-format hook there and assume it works.

Use the normal Home Manager/nix-darwin deployment after the new files are Git-tracked. Don't run `rtk init`: that imperatively edits agent configuration already owned by this repo. No shell aliases replace ordinary commands.

## What should agents filter?

Verbose output intended for reading: test/build output and Git summaries. For example, `rtk git status`, `rtk git diff --stat`, `rtk cargo test`.

Keep exact source reads, machine-readable output and pipelines feeding parsers raw. The guarded hook leaves these untouched; config also excludes curl, wget and `gh api` from native rewrites. Use `RTK_DISABLED=1` or `rtk bypass <command>` when another invocation must remain untouched. Do not rerun a mutating command to recover output.

Summaries can omit relevant information. Read the printed `rtk recall <hash>` reference when details matter, and don't approve a change from a reduced diff alone. Recall storage is local, capped at 200 entries of up to 10 MiB each and seven days. It can contain sensitive command output, so don't sync or publish it. Local tracking retains 30 days. Telemetry is explicitly disabled in both config and the Home Manager session environment.

## How do I check it?

```sh
command -v rtk
rtk --version
rtk config
rtk git status
rtk gain

cd ~/me/public/personal/dotfiles/rtk
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest -v test_claude_hook.py
```

`rtk gain` estimates command-output tokens using byte counts. It is not a model tokenizer, a whole-session token measurement or proof of better coding results. Compare raw and filtered output on representative commands and check that errors and important facts survive.

The pinned 1.1.0 sources document the [CLI-only build](https://github.com/rtk-ai/rtk/blob/v1.1.0/Cargo.toml), [native hooks](https://github.com/rtk-ai/rtk/blob/v1.1.0/src/hooks/hook_cmd.rs) and [configuration](https://github.com/rtk-ai/rtk/blob/v1.1.0/src/core/config.rs). Current documentation: [savings explanation](https://github.com/rtk-ai/rtk/blob/develop/docs/guide/resources/savings-explained.md) and [agent coverage](https://www.rtk-ai.app/docs/resources/agent-coverage/). Recheck those contracts when changing nixpkgs.
