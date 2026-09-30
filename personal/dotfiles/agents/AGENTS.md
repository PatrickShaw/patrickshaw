---
description: Patrick's personal coding practices, applied to all code
alwaysApply: true
---

# Personal coding practices

Single source of truth for my coding standards across every AI harness
(Rovo Dev, Claude Code, Codex, Cursor). Do not duplicate this file — symlink it.
See `~/personal/dotfiles/agents/README.md` for how it is wired up.

## All languages

- **Favour immutability**: Keep state as encapsulated as possible.
- **Encapsulated state**: Where mutable state is unavoidable, ensure it is
  strictly encapsulated and its scope is minimized.
- **Contextual comments**: Use comments to explain *why* a particular piece of
  code exists, especially for complex logic or business rules. Do not use
  comments to explain *what* the code does if the code itself is clear.
- **D.R.Y rule of threes**: If you have repeated a sequence of code three or
  more times, consider refactoring to remove the duplication.
- **No magic numbers**: Numbers with semantic meaning attached to them should
  always be assigned to and used as a variable (e.g. `MAX_RETRIES = 3`).
- **Avoid micro-optimizations**: Focus on understandable, readable code first
  and foremost.
- **No boat anchors / YAGNI**: Avoid defensive programming and "just in case"
  code paths.
- **Fail fast**: Where appropriate, avoid silencing errors by swallowing them or
  falling back on defaults. Instead, be explicit that "this is an error" and
  handle it at a scope that can handle the error best.
- **Single Responsibility**: Each function, class, or module should have one,
  and only one, reason to change.
- **Explicit dependencies**: Avoid hidden dependencies like globals or
  singletons. Make dependencies explicit by passing them as arguments or through
  dependency injection.
- **SOLID**: Incorporate SOLID principles into code (Single Responsibility,
  Open/Closed, Liskov Substitution, Interface Segregation, and Dependency
  Inversion).

## Writing as me

Anything I'll send or publish as myself (Slack/chat, PR descriptions, review
comments, commits, code comments, docs) must sound like me. Load the matching
skill first: `voice-slack`, `voice-pull-requests`, `voice-commits`,
`voice-code-comments`, `voice-docs`. These always apply:

- Short and direct. Lead with the point. No preamble, sign-offs, or closing
  summary.
- Why before what. Link to evidence instead of re-explaining it.
- Casual and candid: hedge opinions (`I think`, `imo`, `personally`), own
  mistakes plainly, light humour is fine.
- Australian/British spelling. Spaced hyphen ` - `, never em dashes.
- Headings and bullets only when structure genuinely helps.
- Never: "I hope this helps", "Great question", "Let me know if...", "This PR
  introduces...", comprehensive/robust/seamless/leverage/delve, emoji headers,
  ✅ checklists, bold on everything.
- Match the register of the genre. Don't fake typos or overdo slang.

## Topic-specific preferences

Detailed preferences are lazy-loaded from skills. Load an applicable preference
skill before writing, reviewing, refactoring, or advising on code in that topic.
