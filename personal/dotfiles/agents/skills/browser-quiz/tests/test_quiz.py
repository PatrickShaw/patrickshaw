import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import sys
import threading
import unittest
import urllib.error
import urllib.request
from unittest.mock import patch

SKILL = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("quiz", SKILL / "scripts" / "quiz.py")
quiz = importlib.util.module_from_spec(SPEC)
with patch.object(sys, "path", [str(SKILL / "scripts"), *sys.path]):
    SPEC.loader.exec_module(quiz)


def modern_example():
    return json.loads((SKILL / "examples" / "sample.json").read_text(encoding="utf-8"))


def example():
    definition = modern_example()
    definition["schemaVersion"] = 1
    for meta in definition["learning"].values():
        meta.pop("choiceExplanations")
    return definition


def report(definition, answers, attempt_id="attempt-1", completed="2026-11-12T06:00:00+00:00"):
    responses = quiz.grade(definition, answers)
    return {
        "schemaVersion": 1, "attemptId": attempt_id,
        "startedAt": completed, "completedAt": completed,
        "quiz": definition, "answers": answers, "responses": responses,
        "score": {"correct": sum(r["outcome"] == "correct" for r in responses), "total": len(responses), "skipped": sum(r["outcome"] == "skipped" for r in responses)},
    }


class QuizTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="tmp_rovo_quiz_", dir=Path.cwd())
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.definition = example()

    def test_validate_single_and_multiple_choice(self):
        self.assertEqual(quiz.validate_quiz(self.definition), self.definition)

    def test_invalid_definitions(self):
        mutations = [
            lambda d: d.update(schemaVersion=2),
            lambda d: d["survey"].update(elements=[]),
            lambda d: d["survey"]["elements"][0].update(correctAnswer="not-a-choice"),
            lambda d: d["survey"]["elements"][0].update(name="self_report_reserved"),
            lambda d: d["survey"]["elements"][1].update(correctAnswer=["earth", "earth"]),
            lambda d: d["survey"]["elements"][0].update(type="html"),
            lambda d: d["learning"].pop("red_planet"),
        ]
        for mutate in mutations:
            with self.subTest(mutation=mutate):
                definition = copy.deepcopy(self.definition)
                mutate(definition)
                with self.assertRaises(ValueError):
                    quiz.validate_quiz(definition)

    def test_public_payload_has_no_keys_explanations_or_generated_html(self):
        self.definition["survey"]["completedHtml"] = "<script>bad()</script>"
        self.definition["survey"]["elements"][0]["visibleIf"] = "false"
        public = json.dumps(quiz.public_survey(self.definition))
        self.assertNotIn("correctAnswer", public)
        self.assertNotIn("iron-rich", public)
        self.assertNotIn("<script>", public)
        self.assertNotIn("visibleIf", public)
        self.assertNotIn("self_report_red_planet", public)
        self.assertNotIn("dropdown", public)

    def test_checkbox_grading_ignores_choice_order(self):
        responses = quiz.grade(self.definition, {"red_planet": "mars", "terrestrial": ["mars", "earth"]})
        self.assertEqual([r["outcome"] for r in responses], ["correct", "correct"])

    def test_skips_guesses_and_too_hard_are_preserved(self):
        responses = quiz.grade(self.definition, {"red_planet": "venus", "self_report_red_planet": "unsure", "self_report_terrestrial": "too_hard"})
        self.assertEqual(responses[0]["outcome"], "incorrect")
        self.assertEqual(responses[0]["selfReport"], "unsure")
        self.assertEqual(responses[1]["outcome"], "skipped")
        self.assertEqual(responses[1]["selfReport"], "too_hard")

    def test_invalid_answers_rejected(self):
        for data in ({"unknown": "x"}, {"red_planet": "pluto"}, {"red_planet": []}, {"terrestrial": ["earth", "earth"]}, {"self_report_red_planet": {}}, {"self_report_red_planet": "mastered"}):
            with self.subTest(data=data), self.assertRaises(ValueError):
                quiz.grade(self.definition, data)

    def test_unicode_round_trip_and_timestamp_collision(self):
        self.definition["survey"]["title"] = "廣東話 soeng2˧˥ [sœːŋ˧˥]"
        first = report(self.definition, {}, "first")
        second = report(self.definition, {}, "second")
        first_path = quiz.save_attempt(self.directory, first)
        second_path = quiz.save_attempt(self.directory, second)
        self.assertNotEqual(first_path, second_path)
        self.assertRegex(first_path.name, r"^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}_\d{3}\.json$")
        self.assertEqual(quiz.load_history(self.directory), [first, second])
        self.assertEqual(len(list((self.directory / "attempts").glob("tmp_rovo_*"))), 0)

    def test_submission_is_idempotent_and_different_resubmit_rejected(self):
        session = quiz.QuizSession(self.definition, self.directory)
        first = session.submit({"red_planet": "mars"})
        self.assertEqual(session.submit({"red_planet": "mars"}), first)
        self.assertEqual(len(quiz.load_history(self.directory)), 1)
        with self.assertRaises(ValueError):
            session.submit({"red_planet": "venus"})

    def test_save_failure_can_be_retried(self):
        session = quiz.QuizSession(self.definition, self.directory)
        with patch.object(quiz, "save_attempt", side_effect=PermissionError("read only")):
            with self.assertRaises(PermissionError):
                session.submit({})
        self.assertIsNone(session.saved)
        session.submit({})
        self.assertEqual(len(quiz.load_history(self.directory)), 1)

    def test_missing_history_is_empty(self):
        self.assertEqual(quiz.history_summary(self.directory)["attemptCount"], 0)

    def test_corrupt_history_is_not_silently_skipped(self):
        path = quiz.save_attempt(self.directory, report(self.definition, {}))
        path.write_text("not json", encoding="utf-8")
        with self.assertRaises(ValueError):
            quiz.load_history(self.directory)

    def test_conflicting_and_duplicate_synced_attempts(self):
        first = report(self.definition, {})
        path = quiz.save_attempt(self.directory, first)
        duplicate = path.with_name("synced-copy.json")
        duplicate.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")
        self.assertEqual(len(quiz.load_history(self.directory)), 1)
        duplicate.write_text(json.dumps(report(self.definition, {"red_planet": "mars"})), encoding="utf-8")
        with self.assertRaises(ValueError):
            quiz.load_history(self.directory)

    def test_three_questions_in_one_attempt_do_not_prove_consolidation(self):
        for index, q in enumerate(self.definition["survey"]["elements"]):
            self.definition["learning"][q["name"]].update(concept="same", skill="same", difficulty="same")
        answers = {"red_planet": "mars", "terrestrial": ["earth", "mars"], "self_report_red_planet": "confident", "self_report_terrestrial": "confident"}
        quiz.save_attempt(self.directory, report(self.definition, answers))
        concept = quiz.history_summary(self.directory)["concepts"][0]
        self.assertEqual(concept["recommendation"], "consolidate")
        self.assertEqual(concept["confidentSuccessAttempts"], 1)

    def test_spread_confident_successes_then_failure(self):
        answers = {"red_planet": "mars", "self_report_red_planet": "confident"}
        for day in range(10, 13):
            quiz.save_attempt(self.directory, report(self.definition, answers, f"a-{day}", f"2026-11-{day}T06:00:00+00:00"))
        concept = next(c for c in quiz.history_summary(self.directory)["concepts"] if c["concept"] == "mars-colour")
        self.assertEqual(concept["recommendation"], "review_later")
        quiz.save_attempt(self.directory, report(self.definition, {"self_report_red_planet": "too_hard"}, "new", "2026-11-13T06:00:00+00:00"))
        concept = next(c for c in quiz.history_summary(self.directory)["concepts"] if c["concept"] == "mars-colour")
        self.assertEqual(concept["recommendation"], "prerequisites")

    def test_feedback_recommendations(self):
        for signal, expected in [("already_known", "respect_self_report"), ("bad_question", "replace_question"), ("unsure", "teach_then_retry")]:
            with self.subTest(signal=signal):
                directory = self.directory / signal
                quiz.save_attempt(directory, report(self.definition, {"red_planet": "mars", "self_report_red_planet": signal}))
                concept = next(c for c in quiz.history_summary(directory)["concepts"] if c["concept"] == "mars-colour")
                self.assertEqual(concept["recommendation"], expected)


class ImmediateFeedbackTests(unittest.TestCase):
    setUp = QuizTests.setUp

    def test_v2_requires_every_choice_explanation(self):
        definition = modern_example()
        quiz.validate_quiz(definition)
        definition["learning"]["red_planet"]["choiceExplanations"].pop("venus")
        with self.assertRaisesRegex(ValueError, "every choice"):
            quiz.validate_quiz(definition)

    def test_only_checked_question_explanation_is_returned(self):
        session = quiz.QuizSession(modern_example(), self.directory)
        response = session.check({"question": "red_planet", "answer": "venus"})
        self.assertEqual(response["outcome"], "incorrect")
        self.assertIn("bright clouds", response["choiceExplanations"]["venus"])
        self.assertEqual(len(session.progress()["responses"]), 1)
        self.assertNotIn("terrestrial", json.dumps(session.progress()))
        self.assertEqual(quiz.load_history(self.directory), [])

    def test_first_answer_locked_and_check_idempotent(self):
        session = quiz.QuizSession(modern_example(), self.directory)
        payload = {"question": "red_planet", "answer": "venus"}
        first = session.check(payload)
        self.assertEqual(session.check(payload), first)
        with self.assertRaisesRegex(ValueError, "first answer"):
            session.check({"question": "red_planet", "answer": "mars"})
        first["answer"] = "mars"
        self.assertEqual(session.progress()["responses"][0]["answer"], "venus")

    def test_cannot_skip_ahead_or_submit_unchecked_v2(self):
        session = quiz.QuizSession(modern_example(), self.directory)
        with self.assertRaisesRegex(ValueError, "order"):
            session.check({"question": "terrestrial", "answer": ["earth"]})
        with self.assertRaisesRegex(ValueError, "Check every"):
            session.submit({})

    def test_final_record_preserves_first_answers_and_old_history(self):
        quiz.save_attempt(self.directory, report(example(), {"red_planet": "mars"}))
        session = quiz.QuizSession(modern_example(), self.directory)
        session.check({"question": "red_planet", "answer": "venus"})
        session.check({"question": "terrestrial", "answer": ["mars", "earth"]})
        answers = {"red_planet": "venus", "terrestrial": ["mars", "earth"]}
        with self.assertRaisesRegex(ValueError, "first checked"):
            session.submit({**answers, "red_planet": "mars"})
        saved = session.submit(answers)
        self.assertEqual(saved["score"]["correct"], 1)
        self.assertEqual(session.submit(answers), saved)
        self.assertEqual(len(quiz.load_history(self.directory)), 2)

    def test_skipped_check_and_failed_final_save_can_retry(self):
        session = quiz.QuizSession(modern_example(), self.directory)
        for name in ["red_planet", "terrestrial"]:
            self.assertEqual(session.check({"question": name, "answer": None})["outcome"], "skipped")
        answers = {"red_planet": None, "terrestrial": None}
        with patch.object(quiz, "save_attempt", side_effect=OSError("disk full")):
            with self.assertRaises(OSError):
                session.submit(answers)
        self.assertIsNone(session.saved)
        self.assertEqual(len(session.progress()["responses"]), 2)
        self.assertEqual(session.submit(answers)["score"]["skipped"], 2)

    def test_repeated_success_without_confidence_is_not_labelled_confident(self):
        for day in range(10, 13):
            quiz.save_attempt(self.directory, report(self.definition, {"red_planet": "mars"}, f"a-{day}", f"2026-11-{day}T06:00:00+00:00"))
        concept = next(c for c in quiz.history_summary(self.directory)["concepts"] if c["concept"] == "mars-colour")
        self.assertEqual(concept["recommendation"], "review_later")
        self.assertEqual(concept["correctFirstAttemptSessions"], 3)
        self.assertEqual(concept["confidentSuccessAttempts"], 0)


class HTTPTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="tmp_rovo_quiz_http_", dir=Path.cwd())
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.session = quiz.QuizSession(example(), self.directory)
        self.server = quiz.ThreadingHTTPServer(("127.0.0.1", 0), quiz.handler_for(self.session, self.directory))
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)
        self.origin = f"http://127.0.0.1:{self.server.server_port}"
        self.url = f"{self.origin}/{self.session.token}/"

    def post(self, data, origin=None):
        request = urllib.request.Request(self.url + "submit", json.dumps(data).encode(), headers={"Content-Type": "application/json", "Origin": origin or self.origin})
        return urllib.request.urlopen(request)

    def test_valid_http_quiz_and_submission(self):
        with urllib.request.urlopen(self.url + "quiz") as response:
            definition = json.load(response)
        self.assertEqual(definition["title"], "A quick space quiz")
        with self.post({"red_planet": "mars"}) as response:
            result = json.load(response)
        self.assertEqual(result["score"]["correct"], 1)
        self.assertEqual(len(quiz.load_history(self.directory)), 1)

    def test_immediate_check_http_and_load_acknowledgement(self):
        def post_route(route, data):
            request = urllib.request.Request(self.url + route, json.dumps(data).encode(), headers={"Content-Type": "application/json", "Origin": self.origin})
            with urllib.request.urlopen(request) as response:
                return json.load(response)
        response = post_route("check", {"question": "red_planet", "answer": "venus"})
        self.assertEqual(response["outcome"], "incorrect")
        with urllib.request.urlopen(self.url + "progress") as response:
            self.assertEqual(len(json.load(response)["responses"]), 1)
        self.assertFalse(self.session.browser_loaded)
        self.assertEqual(post_route("loaded", {}), {"loaded": True})
        self.assertTrue(self.session.browser_loaded)

    def test_check_endpoint_requires_same_origin(self):
        request = urllib.request.Request(self.url + "check", b'{}', headers={"Content-Type": "application/json", "Origin": "https://example.org"})
        with self.assertRaises(urllib.error.HTTPError) as error:
            urllib.request.urlopen(request)
        self.assertEqual(error.exception.code, 403)
        error.exception.close()
        self.assertEqual(self.session.progress()["responses"], [])

    def test_cross_origin_is_rejected(self):
        with self.assertRaises(urllib.error.HTTPError) as error:
            self.post({}, "https://example.org")
        self.assertEqual(error.exception.code, 403)
        error.exception.close()
        self.assertEqual(quiz.load_history(self.directory), [])

    def test_wrong_token_and_rebinding_host_are_rejected(self):
        requests = [self.origin + "/quiz", urllib.request.Request(self.url + "quiz", headers={"Host": f"evil.test:{self.server.server_port}"})]
        for request in requests:
            with self.subTest(request=request), self.assertRaises(urllib.error.HTTPError) as error:
                urllib.request.urlopen(request)
            self.assertEqual(error.exception.code, 404)
            error.exception.close()


if __name__ == "__main__":
    unittest.main()
