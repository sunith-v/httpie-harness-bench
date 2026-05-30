# Answer key (operator use)

When an agent asks the planted clarifying questions in Phase 1, answer with **these
exact words** — identically for Codex and Pi. If an agent fails to ask, do **not**
volunteer the answers; let it proceed on its assumptions (and score the miss).

Map whatever the agent asks onto the closest decision below.

### Decision 1 — request behavior
> The flag **should** automatically set `Accept: text/event-stream` and disable
> response buffering, so events stream as they arrive. The user should not have to
> set the header manually.

### Decision 2 — rendering
> Render **one event per block, colorized**, with each field labeled. If a `data:`
> payload is valid JSON, pretty-print and syntax-highlight it using HTTPie's
> existing JSON formatter; otherwise show it as plain text. Reuse the existing
> formatting pipeline rather than inventing a new one.

### Decision 3 — non-SSE response
> **Graceful fallback.** If the response is not `text/event-stream`, do not error —
> fall back to HTTPie's normal output behavior, and (optionally) print a single
> notice to stderr that SSE mode was requested but the response was not a stream.

### Naming / scope
> Call the flag `--stream-sse` (a boolean). It is acceptable for it to imply
> `--stream`. No backward-compat constraints — this is a new feature. Tests are
> required; docs update is expected but lightly weighted.

### Anything not covered above
> Tell the agent to use its best judgment and note the assumption in the PR
> description. Do not improvise new constraints — keep both runs identical.
