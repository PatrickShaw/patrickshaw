import argparse
from contextlib import contextmanager
from datetime import datetime
import fcntl
import json
import logging
import os
from pathlib import Path
import signal
import subprocess
import sys

LIST_TIMEOUT_SECONDS = 120
REFRESH_TIMEOUT_SECONDS = 15 * 60
STOP_TIMEOUT_SECONDS = 10
ACTIVE_STATUSES = {"running", "queued"}


def cli_from_mcp(config_path):
    server = json.loads(config_path.read_text())["mcpServers"]["grounded"]
    arguments = server["args"]
    executable_index = arguments.index("docs-mcp-server")
    prefix = [server["command"], *arguments[: executable_index + 1]]
    options = arguments[executable_index + 1 :]
    # CLI subcommands open the same store, but don't accept MCP transport flags.
    if "--protocol" in options:
        index = options.index("--protocol")
        options = options[:index] + options[index + 2 :]
    environment = {
        **os.environ,
        **server.get("env", {}),
        "OPENAI_API_KEY": "",
        "DOCS_MCP_APP_TELEMETRY_ENABLED": "false",
    }
    # list has no embedding flag; the shared environment works for both commands.
    if "--embedding-model" in options:
        index = options.index("--embedding-model")
        environment["DOCS_MCP_APP_EMBEDDING_MODEL"] = options[index + 1]
        options = options[:index] + options[index + 2 :]
    return prefix, options, environment


def run_command(command, environment, timeout):
    process = subprocess.Popen(
        command,
        env=environment,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        start_new_session=True,
    )
    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except (subprocess.TimeoutExpired, KeyboardInterrupt):
        # npx starts child processes; stopping only its parent leaves crawlers alive.
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.communicate(timeout=STOP_TIMEOUT_SECONDS)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.communicate()
        raise
    if process.returncode:
        raise RuntimeError(f"Command exited {process.returncode}: {stderr.strip() or stdout.strip()}")
    return stdout


def refresh_targets(libraries):
    for library in libraries:
        for version in library["versions"]:
            yield {
                "library": library["name"],
                "version": version["version"],
                "status": version["status"],
                "source": version.get("sourceUrl"),
            }


def refresh_all(targets, execute, logger):
    results = []
    for target in targets:
        label = f"{target['library']}@{target['version'] or 'rolling'}"
        if target["status"] in ACTIVE_STATUSES:
            logger.info("Skipping active indexing job: %s", label)
            results.append({**target, "result": "skipped-active"})
            continue
        if not target["source"]:
            logger.warning("No saved source to refresh: %s", label)
            results.append({**target, "result": "skipped-no-source"})
            continue
        logger.info("Refreshing %s", label)
        try:
            # Pass even the empty version explicitly so rolling and numbered
            # versions remain separate when a library contains both.
            output = execute(["refresh", target["library"], "--version", target["version"]], REFRESH_TIMEOUT_SECONDS)
        except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
            logger.error("Failed %s: %s", label, error)
            results.append({**target, "result": "failed", "error": str(error)})
            continue
        logger.info("Finished %s: %s", label, output.strip())
        results.append({**target, "result": "refreshed"})
    return results


@contextmanager
def run_lock(path):
    with path.open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            yield False
            return
        yield True


def stop_requested(signum, frame):
    raise KeyboardInterrupt


def main():
    signal.signal(signal.SIGTERM, stop_requested)
    parser = argparse.ArgumentParser(description="Refresh every indexed Grounded library/version without an LLM.")
    parser.add_argument("--mcp-config", type=Path, default=Path.home() / ".rovo/mcp.json")
    parser.add_argument("--state-dir", type=Path, default=Path.home() / ".local/state/grounded-refresh")
    parser.add_argument("--dry-run", action="store_true", help="List targets without changing the index.")
    args = parser.parse_args()
    os.umask(0o077)
    args.state_dir.mkdir(parents=True, exist_ok=True)
    with run_lock(args.state_dir / "run.lock") as acquired:
        if not acquired:
            print("Grounded refresh is already running; skipping.")
            return 0
        handlers = [logging.StreamHandler(sys.stdout)]
        if not args.dry_run:
            handlers.append(logging.FileHandler(args.state_dir / "latest.log", mode="w"))
        logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s", handlers=handlers)
        logger = logging.getLogger("grounded-refresh")
        started = datetime.now().astimezone().isoformat()
        try:
            prefix, options, environment = cli_from_mcp(args.mcp_config)

            def execute(arguments, timeout):
                return run_command([*prefix, *arguments, *options], environment, timeout)

            targets = list(refresh_targets(json.loads(execute(["list", "--output", "json"], LIST_TIMEOUT_SECONDS))))
            if args.dry_run:
                print(json.dumps(targets, indent=2))
                return 0
            logger.info("Found %d library versions; refreshing sequentially", len(targets))
            results = refresh_all(targets, execute, logger)
            failed = sum(result["result"] == "failed" for result in results)
            report = {"startedAt": started, "finishedAt": datetime.now().astimezone().isoformat(), "failed": failed, "results": results}
            (args.state_dir / "latest.json").write_text(json.dumps(report, indent=2) + "\n")
            logger.info("Finished: %d refreshed, %d failed, %d skipped", sum(r["result"] == "refreshed" for r in results), failed, sum(r["result"].startswith("skipped") for r in results))
            return 1 if failed else 0
        except KeyboardInterrupt:
            logger.warning("Grounded refresh stopped; child processes terminated")
            return 130
        except (OSError, KeyError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
            logger.error("Could not run Grounded refresh: %s", error)
            return 1


if __name__ == "__main__":
    raise SystemExit(main())
