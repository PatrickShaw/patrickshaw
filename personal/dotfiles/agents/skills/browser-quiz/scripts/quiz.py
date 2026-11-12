#!/usr/bin/env python3
"""Run local SurveyJS quizzes and summarise their saved learning evidence."""

import argparse
import copy
from datetime import datetime, timedelta, timezone
import errno
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import secrets
import socket
import threading
import time
import urllib.request
from browser import launch_browser

SCHEMA_VERSION = 2
SUPPORTED_VERSIONS = {1, 2}
SURVEY_VERSION = "3.2.5"
MAX_BODY_BYTES = 1_048_576
IDLE_TIMEOUT_SECONDS = 7200
COMPLETED_GRACE_SECONDS = 300
CORRECT_ATTEMPTS = 3
MIN_REVIEW_DATES = 2
ASSETS = {
    "survey.core.min.js": ("survey-core", "46f07eca3a1f07fbafff2864bfc31cb9ab766e8a25dfc2375dcc02df2dbcd253"),
    "survey-core.min.css": ("survey-core", "68fa8ad13a6e09935fbb93baee388c4054576a6524419e3e477a3ae671ad8f41"),
    "survey-js-ui.min.js": ("survey-js-ui", "66587c72ecee48222d9fd2ffc02f603dfe0890631e85204c625a50a582df42f5"),
}
SIGNALS = {
    "confident": "I knew this",
    "unsure": "I was unsure / guessed",
    "too_hard": "Too hard - teach me the basics first",
    "already_known": "Already familiar - ask me something else",
    "bad_question": "Ambiguous or incorrect question",
}
WEB_DIR = Path(__file__).resolve().parent.parent / "web"


def require(condition, message):
    if not condition:
        raise ValueError(message)


def text(value):
    return isinstance(value, str) and bool(value.strip())


def validate_quiz(quiz):
    require(isinstance(quiz, dict), "Quiz must be an object")
    require(quiz.get("schemaVersion") in SUPPORTED_VERSIONS, "Expected schemaVersion: 1 or 2")
    require(text(quiz.get("topic")), "topic must be a non-empty string")
    require(isinstance(quiz.get("contextSources", []), list) and all(text(s) for s in quiz.get("contextSources", [])), "contextSources must be strings")
    survey = quiz.get("survey")
    require(isinstance(survey, dict) and text(survey.get("title")), "survey.title is required")
    require(isinstance(survey.get("description", ""), str), "survey.description must be text")
    questions = survey.get("elements")
    require(isinstance(questions, list) and len(questions) > 0, "survey.elements must contain questions")
    learning = quiz.get("learning")
    require(isinstance(learning, dict), "learning metadata is required")
    names = set()
    for question in questions:
        require(isinstance(question, dict), "Each question must be an object")
        name = question.get("name")
        require(text(name) and name.isascii() and all(c.isalnum() or c in "_-" for c in name), "Question names must use ASCII letters, digits, _ or -")
        require(name not in names and not name.startswith("self_report_"), f"Duplicate or reserved name: {name}")
        names.add(name)
        require(question.get("type") in {"radiogroup", "checkbox"}, f"{name}: use radiogroup or checkbox")
        require(text(question.get("title")), f"{name}: title is required")
        require(isinstance(question.get("description", ""), str), f"{name}: description must be text")
        choices = question.get("choices")
        require(isinstance(choices, list) and len(choices) >= 2, f"{name}: provide at least two choices")
        require(all(isinstance(c, dict) and text(c.get("value")) and text(c.get("text")) for c in choices), f"{name}: choices need string value and text")
        values = [c["value"] for c in choices]
        require(len(set(values)) == len(values), f"{name}: choice values must be unique")
        correct = question.get("correctAnswer")
        if question["type"] == "radiogroup":
            require(isinstance(correct, str) and correct in values, f"{name}: correctAnswer must name a choice")
        else:
            require(isinstance(correct, list) and len(correct) > 0 and all(isinstance(v, str) and v in values for v in correct), f"{name}: correctAnswer must be a non-empty choice array")
            require(len(set(correct)) == len(correct), f"{name}: duplicate correct answers")
        meta = learning.get(name)
        require(isinstance(meta, dict), f"{name}: learning metadata missing")
        for key in ("concept", "skill", "difficulty", "explanation"):
            require(text(meta.get(key)), f"{name}: learning.{key} is required")
        explanations = meta.get("choiceExplanations")
        if quiz["schemaVersion"] >= 2 or explanations is not None:
            require(isinstance(explanations, dict) and set(explanations) == set(values), f"{name}: choiceExplanations must cover every choice exactly")
            require(all(text(reason) for reason in explanations.values()), f"{name}: choice explanations must be non-empty text")
        require(isinstance(meta.get("sources", []), list) and all(text(s) for s in meta.get("sources", [])), f"{name}: sources must be strings")
    require(set(learning) == names, "learning keys must exactly match question names")
    return quiz


def public_survey(quiz):
    pages = []
    for q in quiz["survey"]["elements"]:
        # Only these fields reach SurveyJS: generated HTML, expressions and answer keys stay off the page.
        question = {key: q[key] for key in ("type", "name", "title", "choices")}
        question.update({"description": q.get("description", ""), "choicesOrder": "random", "isRequired": False})
        pages.append({"name": q["name"], "elements": [question]})
    return {
        "title": quiz["survey"]["title"],
        "description": quiz["survey"].get("description", ""),
        "pages": pages, "showProgressBar": True, "progressBarLocation": "top",
        "showQuestionNumbers": "off", "showNavigationButtons": False,
        "showCompletePage": False, "autoAdvanceEnabled": False,
        "widthMode": "responsive",
    }


def grade(quiz, data):
    require(isinstance(data, dict), "answers must be an object")
    names = {q["name"] for q in quiz["survey"]["elements"]}
    require(set(data) <= names | {f"self_report_{n}" for n in names}, "Unexpected answer fields")
    responses = []
    for question in quiz["survey"]["elements"]:
        name = question["name"]
        answer = data.get(name)
        signal = data.get(f"self_report_{name}")
        require(signal is None or isinstance(signal, str) and signal in SIGNALS, f"{name}: invalid self-report")
        allowed = {c["value"] for c in question["choices"]}
        if question["type"] == "checkbox":
            require(answer is None or isinstance(answer, list) and all(isinstance(v, str) and v in allowed for v in answer), f"{name}: invalid choices")
            require(answer is None or len(set(answer)) == len(answer), f"{name}: duplicate choices")
            skipped = answer is None or len(answer) == 0
            correct = not skipped and set(answer) == set(question["correctAnswer"])
        else:
            require(answer is None or isinstance(answer, str) and answer in allowed, f"{name}: invalid choice")
            skipped = answer is None
            correct = not skipped and answer == question["correctAnswer"]
        responses.append({
            "question": name, **quiz["learning"][name],
            "answer": answer, "correctAnswer": question["correctAnswer"],
            "outcome": "skipped" if skipped else "correct" if correct else "incorrect",
            "selfReport": signal,
        })
    return responses


def timestamp_name(when):
    return when.strftime("%Y-%m-%d_%H-%M-%S_") + f"{when.microsecond // 1000:03d}"


def save_attempt(results_dir, report):
    attempts_dir = results_dir / "attempts"
    attempts_dir.mkdir(parents=True, exist_ok=True)
    temporary = attempts_dir / f"tmp_rovo_{report['attemptId']}.json"
    payload = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    temporary.write_text(payload, encoding="utf-8")
    when = datetime.fromisoformat(report["completedAt"])
    # Linking a fully written file prevents partial history reads and never overwrites another device's attempt.
    try:
        while True:
            path = attempts_dir / f"{timestamp_name(when)}.json"
            try:
                path.hardlink_to(temporary)
                return path
            except FileExistsError:
                when += timedelta(milliseconds=1)
    finally:
        temporary.unlink()


def load_history(results_dir):
    reports = []
    for path in sorted((results_dir / "attempts").glob("*.json")):
        if path.name.startswith("tmp_rovo_"):
            continue
        report = json.loads(path.read_text(encoding="utf-8"))
        require(isinstance(report, dict) and report.get("schemaVersion") in SUPPORTED_VERSIONS, f"Unsupported history file: {path}")
        validate_quiz(report["quiz"])
        expected = grade(report["quiz"], report["answers"])
        require(report["responses"] == expected, f"Inconsistent responses in {path}")
        require(text(report.get("attemptId")), f"Missing attemptId in {path}")
        datetime.fromisoformat(report["completedAt"])
        reports.append(report)
    unique = {}
    for report in reports:
        attempt_id = report["attemptId"]
        require(attempt_id not in unique or unique[attempt_id] == report, f"Conflicting copies of attempt {attempt_id}")
        unique[attempt_id] = report
    return sorted(unique.values(), key=lambda r: r["completedAt"])


def history_summary(results_dir):
    reports = load_history(results_dir)
    groups = {}
    for report in reports:
        for response in report["responses"]:
            key = (response["concept"], response["skill"], response["difficulty"])
            groups.setdefault(key, []).append({**response, "attemptId": report["attemptId"], "completedAt": report["completedAt"]})
    concepts = []
    for key, observations in sorted(groups.items()):
        last = observations[-1]
        streak = []
        for observation in reversed(observations):
            if observation["outcome"] != "correct" or observation["selfReport"] not in {None, "confident"}:
                break
            streak.append(observation)
        distinct_attempts = {o["attemptId"] for o in streak}
        dates = {o["completedAt"][:10] for o in streak}
        signal = last["selfReport"]
        if signal == "bad_question":
            recommendation = "replace_question"
        elif signal == "too_hard":
            recommendation = "prerequisites"
        elif signal == "already_known":
            recommendation = "respect_self_report"
        elif last["outcome"] != "correct" or signal == "unsure":
            recommendation = "teach_then_retry"
        elif len(distinct_attempts) >= CORRECT_ATTEMPTS and len(dates) >= MIN_REVIEW_DATES:
            recommendation = "review_later"
        else:
            recommendation = "consolidate"
        concepts.append({
            "concept": key[0], "skill": key[1], "difficulty": key[2],
            "recommendation": recommendation, "observations": len(observations),
            "correctFirstAttemptSessions": len(distinct_attempts),
            "confidentSuccessAttempts": len({o["attemptId"] for o in streak if o["selfReport"] == "confident"}),
            "lastObserved": last["completedAt"], "recent": observations[-5:],
        })
    return {
        "schemaVersion": SCHEMA_VERSION, "attemptCount": len(reports),
        "recentAttempts": [{k: r[k] for k in ("attemptId", "completedAt", "score")} for r in reports[-5:]],
        "concepts": concepts,
        "caution": "Recommendations are transparent heuristics, not a validated mastery or spaced-repetition model. Read notes.md and original attempts when needed.",
    }


def prepare_assets(cache_dir):
    cache_dir.mkdir(parents=True, exist_ok=True)
    for name, (package, expected_hash) in ASSETS.items():
        target = cache_dir / name
        if not target.exists():
            url = f"https://cdn.jsdelivr.net/npm/{package}@{SURVEY_VERSION}/{name}"
            with urllib.request.urlopen(url, timeout=60) as response:
                payload = response.read()
            require(hashlib.sha256(payload).hexdigest() == expected_hash, f"Checksum failed for {name}")
            temporary = cache_dir / f"tmp_rovo_{secrets.token_hex(8)}"
            temporary.write_bytes(payload)
            temporary.replace(target)
        require(hashlib.sha256(target.read_bytes()).hexdigest() == expected_hash, f"Cached {name} is corrupt; remove it and run assets again")


class QuizSession:
    def __init__(self, quiz, results_dir):
        self.quiz = copy.deepcopy(quiz)
        self.results_dir = results_dir
        self.attempt_id = secrets.token_hex(16)
        self.started_at = datetime.now(timezone.utc).isoformat()
        self.token = secrets.token_urlsafe(24)
        self.lock = threading.Lock()
        self.saved = None
        self.checked = {}
        self.browser_loaded = False
        self.completed_monotonic = None

    def progress(self):
        with self.lock:
            return {"responses": copy.deepcopy(list(self.checked.values()))}

    def mark_browser_loaded(self):
        with self.lock:
            if not self.browser_loaded:
                self.browser_loaded = True
                print(json.dumps({"event": "browser_loaded", "attemptId": self.attempt_id}), flush=True)
        return {"loaded": True}

    def check(self, payload):
        require(isinstance(payload, dict) and set(payload) == {"question", "answer"}, "Expected question and answer")
        name = payload["question"]
        answer = payload["answer"]
        questions = self.quiz["survey"]["elements"]
        require(isinstance(name, str) and name in self.quiz["learning"], "Unknown question")
        with self.lock:
            if name in self.checked:
                previous = self.checked[name]
                require(answer == previous["answer"], "The first answer is already recorded; continue to the next question")
                return copy.deepcopy(previous)
            require(self.saved is None, "This quiz is already complete")
            require(questions[len(self.checked)]["name"] == name, "Check questions in order")
            response = next(r for r in grade(self.quiz, {name: answer}) if r["question"] == name)
            self.checked[name] = copy.deepcopy(response)
            return response

    def submit(self, data):
        with self.lock:
            if self.saved is not None:
                require(data == self.saved["answers"], "This attempt was already submitted with different answers")
                return self.saved
            if self.quiz["schemaVersion"] >= 2 or self.checked:
                require(len(self.checked) == len(self.quiz["survey"]["elements"]), "Check every question before finishing")
                first_answers = {name: response["answer"] for name, response in self.checked.items()}
                require(data == first_answers, "Final answers must match the first checked answers")
            responses = grade(self.quiz, data)
            report = {
                "schemaVersion": SCHEMA_VERSION, "attemptId": self.attempt_id,
                "startedAt": self.started_at, "completedAt": datetime.now(timezone.utc).isoformat(),
                "quiz": self.quiz, "answers": data, "responses": responses,
                "score": {"correct": sum(r["outcome"] == "correct" for r in responses), "total": len(responses), "skipped": sum(r["outcome"] == "skipped" for r in responses)},
            }
            path = save_attempt(self.results_dir, report)
            self.saved = report
            self.completed_monotonic = time.monotonic()
            print(json.dumps({"event": "saved", "path": str(path), "score": report["score"]}), flush=True)
            return report


def handler_for(session, cache_dir):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def respond(self, status, content, content_type="application/json; charset=utf-8"):
            payload = content if isinstance(content, bytes) else json.dumps(content, ensure_ascii=False).encode()
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(payload)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Referrer-Policy", "no-referrer")
            self.send_header("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'")
            self.end_headers()
            self.wfile.write(payload)

        def route(self):
            host = self.headers.get("Host")
            port = self.server.server_port
            allowed = {f"[::1]:{port}", f"127.0.0.1:{port}", f"localhost:{port}"}
            prefix = f"/{session.token}/"
            if host not in allowed or not self.path.startswith(prefix):
                return None
            return self.path[len(prefix):]

        def do_GET(self):
            route = self.route()
            if route is None:
                self.respond(404, {"error": "Not found"})
            elif route == "quiz":
                self.respond(200, public_survey(session.quiz))
            elif route == "progress":
                self.respond(200, session.progress())
            elif route == "result":
                with session.lock:
                    self.respond(200, session.saved)
            elif route in {"", "app.js", "choice-feedback.js", "style.css"}:
                name = "index.html" if route == "" else route
                content_type = {"index.html": "text/html", "app.js": "text/javascript", "choice-feedback.js": "text/javascript", "style.css": "text/css"}[name]
                self.respond(200, (WEB_DIR / name).read_bytes(), content_type + "; charset=utf-8")
            elif route in ASSETS:
                content_type = "text/css" if route.endswith(".css") else "text/javascript"
                self.respond(200, (cache_dir / route).read_bytes(), content_type + "; charset=utf-8")
            else:
                self.respond(404, {"error": "Not found"})

        def do_POST(self):
            route = self.route()
            if route not in {"submit", "check", "loaded"}:
                self.respond(404, {"error": "Not found"})
                return
            if self.headers.get("Origin") != f"http://{self.headers.get('Host')}":
                self.respond(403, {"error": "Same-origin browser submission required"})
                return
            try:
                length = int(self.headers.get("Content-Length", "0"))
                require(0 < length <= MAX_BODY_BYTES, "Submission size invalid")
                require(self.headers.get("Content-Type", "").split(";")[0] == "application/json", "Expected application/json")
                data = json.loads(self.rfile.read(length))
                if route == "check":
                    result = session.check(data)
                elif route == "loaded":
                    require(data == {}, "Expected empty load acknowledgement")
                    result = session.mark_browser_loaded()
                else:
                    result = session.submit(data)
                self.respond(200, result)
            except (ValueError, UnicodeDecodeError) as error:
                self.respond(400, {"error": str(error)})
            except OSError as error:
                print(f"Could not save quiz: {error}", flush=True)
                self.respond(500, {"error": "Answers were NOT saved. Check the runner log and retry."})
    return Handler


class IPv6Server(ThreadingHTTPServer):
    address_family = socket.AF_INET6

    def server_bind(self):
        self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
        super().server_bind()


def serve(quiz, results_dir, cache_dir, open_browser, port):
    prepare_assets(cache_dir)
    session = QuizSession(quiz, results_dir)
    handler = handler_for(session, cache_dir)
    servers = []
    running_servers = []
    try:
        try:
            servers.append(IPv6Server(("::1", port), handler))
        except OSError as error:
            if error.errno not in {errno.EAFNOSUPPORT, errno.EADDRNOTAVAIL}:
                raise
        bound_port = servers[0].server_port if servers else port
        servers.append(ThreadingHTTPServer(("127.0.0.1", bound_port), handler))
        for server in servers:
            threading.Thread(target=server.serve_forever, daemon=True).start()
            running_servers.append(server)
        host = "[::1]" if len(servers) == 2 else "127.0.0.1"
        url = f"http://{host}:{servers[0].server_port}/{session.token}/"
        print(json.dumps({"event": "ready", "url": url, "resultsDir": str(results_dir), "attemptId": session.attempt_id}), flush=True)
        if open_browser:
            print(json.dumps(launch_browser(url)), flush=True)
        deadline = time.monotonic() + IDLE_TIMEOUT_SECONDS
        while time.monotonic() < deadline:
            if session.completed_monotonic is not None and time.monotonic() - session.completed_monotonic >= COMPLETED_GRACE_SECONDS:
                break
            time.sleep(1)
    finally:
        for server in running_servers:
            server.shutdown()
        for server in servers:
            server.server_close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    default_cache = Path.home() / ".cache" / "browser-quiz" / SURVEY_VERSION
    assets = commands.add_parser("assets", help="Download pinned assets once; later runs work offline")
    assets.add_argument("--cache-dir", type=Path, default=default_cache)
    validate = commands.add_parser("validate")
    validate.add_argument("--quiz", type=Path, required=True)
    history = commands.add_parser("history")
    history.add_argument("--results-dir", type=Path, required=True)
    runner = commands.add_parser("serve")
    runner.add_argument("--quiz", type=Path, required=True)
    runner.add_argument("--results-dir", type=Path, required=True)
    runner.add_argument("--cache-dir", type=Path, default=default_cache)
    runner.add_argument("--open", action="store_true")
    runner.add_argument("--port", type=int, default=0)
    args = parser.parse_args()
    if args.command == "assets":
        prepare_assets(args.cache_dir.expanduser())
        print(args.cache_dir.expanduser())
    elif args.command == "history":
        print(json.dumps(history_summary(args.results_dir.expanduser()), ensure_ascii=False, indent=2))
    else:
        quiz = validate_quiz(json.loads(args.quiz.expanduser().read_text(encoding="utf-8")))
        if args.command == "validate":
            require(quiz["schemaVersion"] == SCHEMA_VERSION, "Use schemaVersion 2 with choiceExplanations for new quizzes; version 1 remains readable as history")
            print(f"Valid: {len(quiz['survey']['elements'])} questions")
        else:
            serve(quiz, args.results_dir.expanduser(), args.cache_dir.expanduser(), args.open, args.port)


if __name__ == "__main__":
    main()
