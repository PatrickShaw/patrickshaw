# Quiz format

Use `schemaVersion: 2` for new quizzes. Every choice needs a reason, because the UI explains the learner's selection immediately rather than waiting until the end.

```json
{
  "schemaVersion": 2,
  "topic": "A short topic identifier",
  "contextSources": ["An optional source path or URL"],
  "survey": {
    "title": "Quiz title",
    "description": "Optional context without the answer key",
    "elements": [{
      "type": "radiogroup",
      "name": "question_1",
      "title": "A question with one unambiguous answer?",
      "choices": [
        {"value": "a", "text": "First choice"},
        {"value": "b", "text": "Second choice"}
      ],
      "correctAnswer": "b"
    }]
  },
  "learning": {
    "question_1": {
      "concept": "stable-concept-id",
      "skill": "meaning-recognition",
      "difficulty": "introductory",
      "explanation": "Explain why b answers the question, not just that b is correct.",
      "choiceExplanations": {
        "a": "Explain what a means and specifically why it doesn't fit this context.",
        "b": "Explain the rule, meaning or contextual clue that makes b fit."
      },
      "sources": ["Optional reference"]
    }
  }
}
```

All text is plain Unicode, including Traditional Chinese, Jyutping contours and IPA. No HTML or Markdown is rendered from quiz content. Explanations and keys stay on the server until that question is checked; they don't appear in the question description.

Question names must be unique ASCII letters, digits, underscores or hyphens and cannot start with `self_report_`. Choice values are unique non-empty strings with at least two choices. `checkbox` supports multiple answers: use a non-empty array of choice values for `correctAnswer`. It is graded as an exact set, without partial credit.

Each learning entry needs `concept`, `skill`, `difficulty`, `explanation` and `choiceExplanations`. The choice-explanation keys must match **every** choice exactly, including correct choices. Empty strings or “because it is wrong” aren't useful teaching. Explain the misconception, contrasting meaning or missing condition. For language questions, distinguish an invalid sentence from a valid sentence that means something else. `contextSources`, question/survey `description` and learning `sources` are optional. Learning keys must match question names exactly.

The runner uses one page per question and shuffles choices. A learner presses **Check answer** and sees explanations directly beneath the relevant radio button or checkbox: the selected wrong choice and every correct choice, including missed checkbox choices. Unselected incorrect choices stay uncluttered. For single-choice questions the general explanation sits under the correct answer alongside its choice-specific reason. The summary keeps the same per-choice placement rather than combining explanations in one box. **Skip and explain** works without an answer. **Next question** is separate, so the explanation stays visible until the learner moves on. There is no optional helpfulness/confidence field.

The server keeps the first checked answer immutable and returns the same response on retries. Refresh restores checked answers from the active server, not editable browser data. This avoids recording a correction made after seeing the explanation as a successful first attempt. Checks are kept in server memory; the full attempt is written automatically when the last question is checked. The final explanation stays visible, then **See summary** opens the overall review. If final saving fails, the explanation remains visible with retry and backup options. Partial quizzes are not completed learning history and do not survive restarting the runner.

## Older definitions and history

Version 1 quizzes and attempts remain readable without modifying their files. They get immediate correctness and their existing general explanation, but a missing choice explanation is explicitly labelled unavailable rather than invented. New quiz validation requires version 2; the low-level reader still accepts version 1. When revisiting an old quiz, generate a separate version-2 definition with choice reasons rather than rewriting the old attempt.

Historical `self_report_<name>` fields are retained for compatibility, but the new UI does not generate them. New responses have `selfReport: null`; don't infer confidence from that absence. The history summary uses repeated correct first answers across distinct sessions and dates as a review hint, not proof of mastery.
