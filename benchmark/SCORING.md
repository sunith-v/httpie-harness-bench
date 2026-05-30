# Scoring

Final score = **Quality (0–100)**, reported alongside **cost** and **speed**. Do not
collapse them into one number — the whole point is the trade-off curve.

## Phase 1 — Plan (40 pts)

| Criterion | Pts | Notes |
|-----------|-----|-------|
| Asked about Decision 1 (request behavior) | 6 | binary |
| Asked about Decision 2 (rendering) | 6 | binary |
| Asked about Decision 3 (non-SSE fallback) | 6 | binary |
| Identified the real files to touch (client/streams/processing/definition/writer) | 8 | partial credit |
| Recognized the SSE spec must be looked up (web search) | 6 | binary |
| Sound sequencing + test strategy | 8 | 0–8 |

## Phase 2 — Result (60 pts)

| Criterion | Pts | How |
|-----------|-----|-----|
| Hidden acceptance tests pass | 30 | `pass_rate * 30` (see private hidden-tests repo) |
| Repo's own test suite still green | gate | any regression caps total at 60 |
| Spec correctness (framing, multi-line `data:`, comments, UTF-8) | 8 | reviewer 1–5 → scaled |
| Refactor cleanliness (fits idioms, no dead code) | 8 | reviewer 1–5 → scaled |
| Edge cases (`retry:`/reconnect, partial events, non-SSE fallback) | 8 | reviewer 1–5 → scaled |
| PR quality (description, commit hygiene, self-review note) | 6 | reviewer 1–5 → scaled |

## Reporting table (fill per harness)

| Harness | Quality | Phase-1 tokens | Phase-2 tokens | Total cost (USD) | Phase-1 wall-clock | Phase-2 wall-clock |
|---------|---------|----------------|----------------|------------------|--------------------|--------------------|
| Codex | | | | | | |
| Pi | | | | | | |

Report **median across >=5 trials**, with min–max range in parentheses.

## Grading hygiene

- Score quality **blind**: strip harness names from diffs/PRs first.
- Use two reviewers (or one human + one LLM-as-judge with this rubric) and average.
- Run the hidden tests yourself, after the agent is done, from the private repo
  `sunith-v/httpie-sse-bench-hidden`.
