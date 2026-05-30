# Harness Benchmark: Codex vs. Pi (GPT-5.5-high)

This repo is a frozen fork of [httpie/cli](https://github.com/httpie/cli), used to
compare two coding-agent harnesses (**Codex** and **Pi**) driving the **same model
(GPT-5.5-high)** through one realistic, multi-capability task.

Base state is frozen at tag `bench-base` (httpie/cli master @ `5b604c3`).

## What we measure

For each harness, across two phases:

- **Tokens / cost** — input, cached-input, output, and reasoning tokens (reported
  separately), converted to USD. GPT-5.5 pricing (per 1M tokens):
  **input $5.00 · cached input $0.50 · output $30.00** (reasoning billed as output).
  `run_phase.sh` computes `cost_usd` automatically from the counts you paste in.
- **Speed** — wall-clock per phase, plus time-to-first-edit and tool-call count.
- **Quality** — hidden acceptance tests + repo's own suite + a scored rubric.

## The task

See [`TASK.md`](TASK.md). One task forces every required capability: web search,
pulling repo context, asking clarifying questions, writing a plan, a multi-file
refactor + implementation, code review, and pushing a PR.

## The two phases

| Phase | Branch | Deliverable | Counters reset before |
|-------|--------|-------------|-----------------------|
| 1 — Plan | `phase-1-plan` | `PLAN.md` + clarifying questions | yes |
| 2 — Result | `phase-2-result` | implemented feature + PR + self-review | yes |

Between phases you answer the agent's questions using the **fixed**
[`ANSWER_KEY.md`](ANSWER_KEY.md) — identical answers for both harnesses, for fairness.

## How to run (per harness)

```bash
# Phase 1 — plan
git checkout phase-1-plan
./benchmark/run_phase.sh codex plan   # inside the session type:  /plan
./benchmark/run_phase.sh pi plan      # inside the session type:  /plannotator
# (answer questions from ANSWER_KEY.md, identically for both)

# Phase 2 — implement + PR
git checkout phase-2-result
./benchmark/run_phase.sh codex result
./benchmark/run_phase.sh pi result
```

The plan step uses each tool's **interactive** slash command (`/plan` in codex,
`/plannotator` in pi) — typed inside the running session, not as a shell flag.
The runner launches the CLI, times the session, then prompts you for the token
counts and writes `benchmark/metrics/<harness>-<phase>-<trial>.json` with cost filled in.

Each invocation brackets the run with timestamps and writes a
`benchmark/metrics/<harness>-<phase>-<trial>.json` stub for you to fill from the
harness's own usage log.

**Run >=5 trials per harness per phase.** These agents are non-deterministic; report
median + range, never a single run.

## Fairness rules (do not skip)

1. Identical start: every run begins at the phase branch HEAD (which descends from
   `bench-base`).
2. Identical prompt (`TASK.md`) and identical answers (`ANSWER_KEY.md`).
3. Identical allowed tools + network policy + model sampling settings.
4. **Block the `github.com/httpie/cli` upstream domain** during runs so the agent
   can't find an upstream implementation. (Anti-contamination.)
5. Hidden acceptance tests live in a **separate private repo**
   (`sunith-v/httpie-sse-bench-hidden`), never here.
6. Grade blind: strip harness identifiers from diffs before scoring quality.

## Scoring

See [`SCORING.md`](SCORING.md).
