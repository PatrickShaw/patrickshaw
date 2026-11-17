const {test} = require('node:test');
const assert = require('node:assert/strict');
require('../web/audio.js');

class Element {
  constructor(document, tag) {
    this.ownerDocument = document;
    this.tagName = tag;
    this.children = [];
    this.attributes = {};
    this.events = {};
    this.open = false;
    this.paused = true;
    this.playbackRate = 1;
  }
  append(...children) { this.children.push(...children); }
  replaceChildren(...children) { this.children = children; }
  setAttribute(key, value) { this.attributes[key] = value; }
  addEventListener(event, callback) { this.events[event] = callback; }
  pause() { this.paused = true; }
  querySelectorAll(tag) {
    return this.children.flatMap(child => [ ...(child.tagName === tag ? [child] : []), ...child.querySelectorAll(tag)]);
  }
}
const document = {createElement(tag) { return new Element(document, tag); }};
const fixture = {
  transcript: 'Visible transcript', pronunciation: 'Hidden pronunciation <script>not HTML</script>',
  pronunciationLabel: 'Show pronunciation', attribution: 'Test source',
  url: 'https://untrusted.example/ignored.wav', file: '/not/a/browser/path.wav',
};

function rendered() {
  const container = document.createElement('section');
  QuizAudio.render(container, fixture, 'question_1');
  return container;
}

test('transcript is outside a collapsed plain-text pronunciation disclosure', () => {
  const container = rendered();
  assert.equal(container.hidden, false);
  assert.equal(container.children[0].textContent, fixture.transcript);
  const [details] = container.querySelectorAll('details');
  assert.equal(details.open, false);
  assert.deepEqual(details.children.map(x => x.tagName), ['summary', 'p']);
  assert.equal(details.children[1].textContent, fixture.pronunciation);
  assert.equal(container.querySelectorAll('script').length, 0);
});
test('playback uses local route, controls and default speed without autoplay', () => {
  const [player] = rendered().querySelectorAll('audio');
  assert.equal(player.src, 'audio/question_1');
  assert.equal(player.controls, true);
  assert.equal(player.preload, 'metadata');
  assert.equal(player.autoplay, undefined);
  assert.equal(player.playbackRate, 1);
  assert.equal(player.attributes['aria-label'], 'Play question audio');
});
test('a new question stops old audio and collapses pronunciation again', () => {
  const container = rendered();
  const [oldPlayer] = container.querySelectorAll('audio');
  oldPlayer.paused = false;
  container.querySelectorAll('details')[0].open = true;
  QuizAudio.render(container, {...fixture, transcript: 'Second'}, 'question_2');
  assert.equal(oldPlayer.paused, true);
  assert.equal(container.querySelectorAll('details')[0].open, false);
  assert.equal(container.querySelectorAll('audio').length, 1);
  assert.equal(container.children[0].textContent, 'Second');
});
test('text-only question removes the player and pronunciation region', () => {
  const container = rendered();
  QuizAudio.render(container, undefined, 'text_only');
  assert.equal(container.hidden, true);
  assert.deepEqual(container.children, []);
});
test('playback errors retain transcript and disclosure with explicit fallback', () => {
  const container = rendered();
  const [player] = container.querySelectorAll('audio');
  player.events.error();
  assert.equal(player.hidden, true);
  assert.equal(container.children[0].textContent, fixture.transcript);
  assert.equal(container.querySelectorAll('details')[0].open, false);
  const status = container.children.find(x => x.attributes.role === 'status');
  assert.equal(status.hidden, false);
  assert.match(status.textContent, /Audio is unavailable/);
});
test('generic pronunciation label is used when unspecified', () => {
  const container = document.createElement('section');
  QuizAudio.render(container, {...fixture, pronunciationLabel: undefined}, 'q');
  assert.equal(container.querySelectorAll('summary')[0].textContent, 'Show pronunciation');
});
