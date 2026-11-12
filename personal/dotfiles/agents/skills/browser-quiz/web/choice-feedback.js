"use strict";

(() => {
  function valuesOf(value) {
    return Array.isArray(value) ? value : value === null || value === undefined ? [] : [value];
  }

  function forChoice(question, response, value) {
    const correct = valuesOf(response.correctAnswer).includes(value);
    const selected = valuesOf(response.answer).includes(value);
    if (!correct && !selected) return null;
    const label = correct
      ? selected ? "Your answer - correct" : response.outcome === "skipped" ? "Correct answer" : "Correct answer - not selected"
      : "Your answer - incorrect";
    const reason = response.choiceExplanations?.[value];
    const explanations = correct
      ? question.type === "radiogroup" ? [response.explanation, reason] : [reason ?? response.explanation]
      : [reason ?? "This older quiz has no explanation for this choice. Ask your agent to explain the difference."];
    return {kind: correct ? "correct" : "incorrect", label, paragraphs: [...new Set(explanations.filter((text) => text !== undefined))]};
  }

  function explanationNode(feedback, id) {
    const note = document.createElement("div");
    note.className = `choice-explanation choice-explanation--${feedback.kind}`;
    note.id = id;
    note.tabIndex = -1;
    const heading = document.createElement("strong");
    heading.textContent = feedback.label;
    note.append(heading);
    feedback.paragraphs.forEach((text) => {
      const paragraph = document.createElement("p");
      paragraph.textContent = text;
      note.append(paragraph);
    });
    return note;
  }

  function attach(root, question, response) {
    // Page transitions can briefly retain the previous question, with the same choice values.
    root.querySelectorAll('input[type="radio"], input[type="checkbox"]').forEach((input) => {
      if (input.closest(".sd-question")?.getAttribute("data-name") !== question.name) return;
      const feedback = forChoice(question, response, input.value);
      if (feedback === null) return;
      const item = input.closest(".sd-item");
      if (item === null) throw new Error("SurveyJS choice container was not found");
      const id = `${input.id}-explanation`;
      if (item.querySelector(".choice-explanation") === null) {
        item.append(explanationNode(feedback, id));
      }
      const describedBy = new Set((input.getAttribute("aria-describedby") ?? "").split(" ").filter(Boolean));
      describedBy.add(id);
      input.setAttribute("aria-describedby", [...describedBy].join(" "));
    });
  }

  globalThis.QuizChoiceFeedback = {forChoice, explanationNode, attach};
})();
