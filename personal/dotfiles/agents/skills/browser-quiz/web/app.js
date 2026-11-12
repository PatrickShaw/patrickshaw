"use strict";

const statusElement = document.getElementById("status");
const feedbackElement = document.getElementById("answer-feedback");
const resultsElement = document.getElementById("results");
const controlsElement = document.getElementById("controls");
const checkButton = document.getElementById("check");
const skipButton = document.getElementById("skip");
const nextButton = document.getElementById("next");
const retryButton = document.getElementById("retry");
const downloadButton = document.getElementById("download");

function node(tag, text, className) {
  const element = document.createElement(tag);
  element.textContent = text;
  if (className !== undefined) element.className = className;
  return element;
}

async function request(path, options) {
  const response = await fetch(path, options);
  if (!response.ok) {
    const failure = await response.json();
    throw new Error(failure.error ?? `Request failed (${response.status})`);
  }
  return response.json();
}

function post(path, data) {
  return request(path, {method: "POST", headers: {"Content-Type": "application/json"}, body: JSON.stringify(data)});
}

function valuesOf(value) {
  return Array.isArray(value) ? value : value === null || value === undefined ? [] : [value];
}

function reviewCard(question, response) {
  const labels = {correct: "Correct", incorrect: "Not quite", skipped: "Let's learn this one"};
  const card = node("article", "", `review ${response.outcome}`);
  card.append(node("h2", labels[response.outcome]));
  card.append(node("p", question.title, "question-title"));
  question.choices.forEach((choice, index) => {
    const item = node("div", "", "review-choice");
    const label = node("label", "", "review-choice__label");
    const input = document.createElement("input");
    input.type = question.type === "checkbox" ? "checkbox" : "radio";
    input.disabled = true;
    input.checked = valuesOf(response.answer).includes(choice.value);
    label.append(input, node("span", choice.text));
    item.append(label);
    const feedback = QuizChoiceFeedback.forChoice(question, response, choice.value);
    if (feedback !== null) {
      const id = `review-${question.name}-${index}`;
      input.setAttribute("aria-describedby", id);
      item.append(QuizChoiceFeedback.explanationNode(feedback, id));
    }
    card.append(item);
  });
  return card;
}

function renderResults(report) {
  document.title = report.quiz.survey.title;
  document.getElementById("survey").hidden = true;
  controlsElement.hidden = true;
  feedbackElement.hidden = true;
  retryButton.hidden = true;
  downloadButton.hidden = true;
  resultsElement.replaceChildren();
  resultsElement.hidden = false;
  resultsElement.append(node("h1", `${report.score.correct} / ${report.score.total}`, "score"));
  resultsElement.append(node("p", "Practice complete. Your first answers are saved.", "result-heading"));
  report.responses.forEach((response, index) => resultsElement.append(reviewCard(report.quiz.survey.elements[index], response)));
  statusElement.textContent = "Saved locally. You can return to your agent or close this tab.";
  resultsElement.focus();
}

function downloadAnswers(answers) {
  const blob = new Blob([JSON.stringify(answers, null, 2)], {type: "application/json"});
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = "unsaved-quiz-answers.json";
  link.click();
  URL.revokeObjectURL(url);
}

class Practice {
  constructor(survey, definition, responses, storageKey) {
    this.survey = survey;
    this.definition = definition;
    this.responses = new Map(responses.map((response) => [response.question, response]));
    this.storageKey = storageKey;
    this.report = null;
    this.choiceRoot = document.getElementById("survey");
    // SurveyJS replaces choice nodes when read-only mode or the current page changes.
    this.choiceObserver = new MutationObserver(() => this.decorateChoices());
    this.choiceObserver.observe(this.choiceRoot, {childList: true, subtree: true});
  }

  decorateChoices() {
    const question = this.question();
    const response = this.responses.get(question.name);
    if (response !== undefined) QuizChoiceFeedback.attach(this.choiceRoot, question, response);
  }

  question() {
    return this.definition.pages[this.survey.currentPageNo].elements[0];
  }

  answers() {
    return Object.fromEntries([...this.responses].map(([name, response]) => [name, response.answer]));
  }

  showFeedback(response) {
    this.survey.readOnly = true;
    checkButton.hidden = true;
    skipButton.hidden = true;
    nextButton.hidden = false;
    const labels = {correct: "Correct", incorrect: "Not quite", skipped: "Let's learn this one"};
    feedbackElement.replaceChildren(node("p", labels[response.outcome], `answer-outcome ${response.outcome}`));
    feedbackElement.hidden = false;
    this.decorateChoices();
    nextButton.textContent = this.survey.isLastPage ? "See summary" : "Next question";
    nextButton.disabled = this.survey.isLastPage && this.report === null;
    statusElement.textContent = "Your first answer is recorded for this session. Read the explanation, then continue.";
    requestAnimationFrame(() => this.choiceRoot.querySelector(".choice-explanation")?.focus());
  }

  showQuestion() {
    feedbackElement.hidden = true;
    retryButton.hidden = true;
    nextButton.hidden = true;
    checkButton.hidden = false;
    skipButton.hidden = false;
    checkButton.disabled = false;
    skipButton.disabled = false;
    this.survey.readOnly = false;
    statusElement.textContent = `Question ${this.survey.currentPageNo + 1} of ${this.definition.pages.length}. Check your answer to learn why.`;
    this.survey.focusFirstQuestion();
  }

  async check(skip) {
    const question = this.question();
    const answer = skip ? null : this.survey.getValue(question.name) ?? null;
    if (!skip && valuesOf(answer).length === 0) {
      statusElement.textContent = "Choose an answer, or use Skip and explain.";
      return;
    }
    const payload = {question: question.name, answer};
    this.survey.readOnly = true;
    checkButton.disabled = true;
    skipButton.disabled = true;
    statusElement.textContent = "Checking your answer…";
    await this.sendCheck(payload);
  }

  async sendCheck(payload) {
    retryButton.hidden = true;
    try {
      const response = await post("check", payload);
      this.responses.set(response.question, response);
      this.survey.setValue(response.question, response.answer);
      this.showFeedback(response);
      if (this.survey.isLastPage) await this.save();
    } catch (error) {
      statusElement.textContent = `Couldn't confirm this answer: ${error.message}. Retry with the same answer.`;
      retryButton.textContent = "Retry checking answer";
      retryButton.hidden = false;
      retryButton.onclick = () => this.sendCheck(payload);
    }
  }

  async save() {
    retryButton.hidden = true;
    statusElement.textContent = "Saving your first answers…";
    try {
      this.report = await post("submit", this.answers());
      nextButton.disabled = false;
      sessionStorage.removeItem(this.storageKey);
      statusElement.textContent = "All answers saved locally. Read the explanation, then see your summary.";
      downloadButton.hidden = true;
    } catch (error) {
      statusElement.textContent = `Answers have NOT been confirmed saved: ${error.message}`;
      retryButton.textContent = "Retry saving answers";
      retryButton.hidden = false;
      retryButton.onclick = () => this.save();
      downloadButton.hidden = false;
      downloadButton.onclick = () => downloadAnswers(this.answers());
    }
  }

  next() {
    if (this.survey.isLastPage) {
      if (this.report !== null) {
        this.choiceObserver.disconnect();
        renderResults(this.report);
      }
      return;
    }
    this.survey.currentPageNo += 1;
    this.showQuestion();
  }

  async initialise() {
    controlsElement.hidden = false;
    checkButton.onclick = () => this.check(false);
    skipButton.onclick = () => this.check(true);
    nextButton.onclick = () => this.next();
    if (this.responses.size === 0) {
      this.showQuestion();
      return;
    }
    // A reload returns to the last explanation, not to an opportunity to change the first answer.
    this.survey.currentPageNo = this.responses.size - 1;
    this.showFeedback(this.responses.get(this.question().name));
    if (this.survey.isLastPage) await this.save();
  }
}

async function start() {
  const previous = await request("result");
  if (previous !== null) {
    renderResults(previous);
    await post("loaded", {});
    return;
  }
  const definition = await request("quiz");
  const progress = await request("progress");
  const survey = new Survey.Model(definition);
  survey.applyTheme({
    themeName: "default", colorPalette: "light", isPanelless: true,
    cssVariables: {
      "--sjs-primary-backcolor": "#4d5ce5", "--sjs-primary-backcolor-dark": "#3443c5",
      "--sjs-primary-backcolor-light": "#eef0ff", "--sjs-corner-radius": "12px",
      "--sjs-font-family": "system-ui, sans-serif", "--sjs-general-backcolor": "#ffffff",
      "--sjs-general-backcolor-dim": "#f5f6fa",
    },
  });
  const storageKey = `quiz-draft:${location.pathname}`;
  const savedDraft = sessionStorage.getItem(storageKey);
  const firstAnswers = Object.fromEntries(progress.responses.map((response) => [response.question, response.answer]));
  survey.data = {...(savedDraft === null ? {} : JSON.parse(savedDraft)), ...firstAnswers};
  survey.onValueChanged.add((sender) => sessionStorage.setItem(storageKey, JSON.stringify(sender.data)));
  survey.render(document.getElementById("survey"));
  document.title = definition.title;
  const practice = new Practice(survey, definition, progress.responses, storageKey);
  await practice.initialise();
  await post("loaded", {});
}

start().catch((error) => {
  statusElement.textContent = `The quiz could not load: ${error.message}. Check that the local runner is still running.`;
});
