# Task (give this verbatim to both harnesses)

> Add first-class support for **Server-Sent Events (SSE)** to HTTPie.
>
> When a response is an event stream, HTTPie should consume it **incrementally** and
> render each event in a readable way **as it arrives**, rather than buffering the
> whole response. Add a CLI flag to opt into this behavior, wire up the appropriate
> request handling, integrate it with the existing output/formatting pipeline, and
> cover it with tests. Then open a pull request.

That is the entire brief. It is **deliberately under-specified** — part of what we
are testing is whether the harness asks good clarifying questions before building.

## Capabilities this task is designed to exercise

- **Web search** — you will need the Server-Sent Events / `text/event-stream`
  specification (the `event:` / `data:` / `id:` / `retry:` fields, blank-line event
  framing, comment lines beginning with `:`, UTF-8 decoding rules). Don't guess the
  wire format.
- **Repo context** — find how HTTPie currently streams responses and how its output
  processing/formatting pipeline works before changing it. Relevant areas include
  `httpie/client.py`, `httpie/output/streams.py`, `httpie/output/processing.py`,
  `httpie/output/formatters/`, `httpie/output/writer.py`, and the CLI definition in
  `httpie/cli/definition.py` (note the existing `--stream` flag near line 504).
- **Clarifying questions** — see the three open design decisions below; ask, don't
  assume.
- **Plan** — Phase 1 deliverable.
- **Multi-file refactor + implementation** — CLI flag + request behavior +
  streaming/buffering + output formatting + tests + docs.
- **Code review** — self-review before opening the PR.
- **Push to GitHub** — open the PR against the `phase-2-result` branch of this fork.

## Open design decisions (do NOT resolve these yourself — ask)

1. Should the new flag automatically set `Accept: text/event-stream` and
   force-disable response buffering, or should it only format whatever the server
   returns regardless of headers?
2. How should each event be rendered — colorized / pretty-printed (and should a
   JSON `data:` payload be parsed and highlighted), or raw passthrough?
3. What should happen when the response is **not** an event stream — a hard error,
   or a graceful fallback to normal output?

The benchmark operator will answer these from a fixed key. Wait for the answers
before implementing.
