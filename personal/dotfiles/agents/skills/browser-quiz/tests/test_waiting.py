from contextlib import redirect_stdout
from datetime import datetime, timedelta, timezone
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import time
import unittest
from unittest.mock import Mock, patch

from test_quiz import SKILL, example, quiz


class LifecycleTests(unittest.TestCase):
    def test_server_lasts_six_hours_even_after_completion(self):
        self.assertEqual(quiz.QUIZ_LIFETIME_SECONDS, timedelta(hours=6).total_seconds())
        for completed in (False, True):
            with self.subTest(completed=completed):
                session = quiz.QuizSession(example(), Path("unused"))
                session.saved = {"completed": True} if completed else None
                ipv6 = Mock(server_port=8123)
                ipv4 = Mock(server_port=8123)
                output = io.StringIO()
                with (
                    patch.object(quiz, "prepare_assets"),
                    patch.object(quiz, "QuizSession", return_value=session),
                    patch.object(quiz, "IPv6Server", return_value=ipv6),
                    patch.object(quiz, "ThreadingHTTPServer", return_value=ipv4),
                    patch.object(quiz.threading, "Thread"),
                    patch.object(quiz.time, "monotonic", side_effect=[0, 0, 301, 7201, 21599, 21600]),
                    patch.object(quiz.time, "sleep") as sleep,
                    redirect_stdout(output),
                ):
                    quiz.serve(example(), Path("unused"), Path("unused"), False, 0)
                self.assertEqual(sleep.call_count, 4)
                events = [json.loads(line) for line in output.getvalue().splitlines()]
                self.assertEqual([event["event"] for event in events], ["ready", "expired"])
                self.assertEqual(events[0]["pid"], os.getpid())
                self.assertEqual(events[0]["attemptId"], events[1]["attemptId"])
                seconds_left = (datetime.fromisoformat(events[0]["expiresAt"]) - datetime.now(timezone.utc)).total_seconds()
                self.assertAlmostEqual(seconds_left, 21600, delta=2)
                for server in (ipv6, ipv4):
                    server.shutdown.assert_called_once()
                    server.server_close.assert_called_once()

    def test_interruption_still_closes_both_listeners(self):
        ipv6 = Mock(server_port=8123)
        ipv4 = Mock(server_port=8123)
        with (
            patch.object(quiz, "prepare_assets"),
            patch.object(quiz, "IPv6Server", return_value=ipv6),
            patch.object(quiz, "ThreadingHTTPServer", return_value=ipv4),
            patch.object(quiz.threading, "Thread"),
            patch.object(quiz.time, "sleep", side_effect=KeyboardInterrupt),
            redirect_stdout(io.StringIO()),
            self.assertRaises(KeyboardInterrupt),
        ):
            quiz.serve(example(), Path("unused"), Path("unused"), False, 0)
        for server in (ipv6, ipv4):
            server.shutdown.assert_called_once()
            server.server_close.assert_called_once()


class DocumentedWaitLoopTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="tmp_rovo_wait_", dir=Path.cwd())
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.attempts = self.directory / "attempts"
        self.attempts.mkdir()
        skill = (SKILL / "SKILL.md").read_text(encoding="utf-8")
        self.code = compile(skill.split("<<'PY'\n", 1)[1].split("\nPY\n", 1)[0], "documented-wait-loop", "exec")
        self.output = io.StringIO()

    def wait(self, clock=(0, 0, 241), sleep=None, process_error=None, expired=False):
        expiry = datetime.now(timezone.utc) + timedelta(hours=-1 if expired else 6)
        args = ["-", str(self.directory), "current-attempt", str(os.getpid()), expiry.isoformat()]
        with (
            patch.object(sys, "argv", args),
            patch.object(time, "monotonic", side_effect=clock),
            patch.object(time, "sleep", side_effect=sleep),
            patch.object(os, "kill", side_effect=process_error),
            redirect_stdout(self.output),
            self.assertRaises(SystemExit) as stopped,
        ):
            exec(self.code, {})
        return stopped.exception.code

    def write_attempt(self, name, attempt_id):
        path = self.attempts / name
        path.write_text(json.dumps({"attemptId": attempt_id}), encoding="utf-8")
        return path

    def test_exact_attempt_only_and_ignore_partial_files(self):
        self.write_attempt("other.json", "other-attempt")
        self.write_attempt("tmp_rovo_pending.json", "current-attempt")
        def complete(_):
            self.write_attempt("completed.json", "current-attempt")
        self.assertEqual(self.wait(sleep=complete), 0)
        self.assertEqual(self.output.getvalue().strip(), str(self.attempts / "completed.json"))

    def test_pending_slice_renews_without_quiz_expiry(self):
        self.write_attempt("old.json", "old-attempt")
        self.assertEqual(self.wait(), 75)
        self.assertEqual(self.output.getvalue(), "")

    def test_success_wins_over_expiry_or_stopped_process(self):
        self.write_attempt("completed.json", "current-attempt")
        self.assertEqual(self.wait(expired=True, process_error=ProcessLookupError()), 0)

    def test_expiry_stops_waiting(self):
        self.assertEqual(self.wait(expired=True), "Quiz expired before a completed attempt was found")

    def test_dead_server_stops_waiting(self):
        self.assertEqual(self.wait(process_error=ProcessLookupError()), "Quiz server stopped before a completed attempt was found")

    def test_malformed_history_is_an_error_not_infinite_waiting(self):
        (self.attempts / "broken.json").write_text("not JSON", encoding="utf-8")
        with self.assertRaises(json.JSONDecodeError):
            self.wait()


if __name__ == "__main__":
    unittest.main()
