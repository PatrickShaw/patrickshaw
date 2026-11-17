"use strict";

(() => {
  function textNode(document, tag, text, className) {
    const element = document.createElement(tag);
    element.textContent = text;
    if (className) element.className = className;
    return element;
  }

  function clear(container) {
    container.querySelectorAll("audio").forEach((audio) => audio.pause());
    container.replaceChildren();
    container.hidden = true;
  }

  function render(container, audio, questionName) {
    clear(container);
    if (audio === undefined) return;
    const document = container.ownerDocument;
    const player = document.createElement("audio");
    player.controls = true;
    player.preload = "metadata";
    // The runner owns this route; saved quiz metadata never supplies a remote URL.
    player.src = `audio/${encodeURIComponent(questionName)}`;
    player.setAttribute("aria-label", "Play question audio");
    const pronunciation = document.createElement("details");
    pronunciation.className = "audio-pronunciation";
    pronunciation.append(
      textNode(document, "summary", audio.pronunciationLabel ?? "Show pronunciation"),
      textNode(document, "p", audio.pronunciation),
    );
    const error = textNode(document, "p", "Audio is unavailable. Continue with the text; pronunciation is available below.", "audio-error");
    error.setAttribute("role", "status");
    error.hidden = true;
    player.addEventListener("error", () => {
      player.hidden = true;
      error.hidden = false;
    });
    container.append(
      textNode(document, "p", audio.transcript, "audio-transcript"),
      player,
      error,
      pronunciation,
      textNode(document, "p", audio.attribution, "audio-attribution"),
    );
    container.hidden = false;
  }

  globalThis.QuizAudio = Object.freeze({render, clear});
})();
