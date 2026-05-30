# Harness Benchmark: Codex vs. Pi (GPT-5.5-high)

This repo is a frozen fork of [httpie/cli](https://github.com/httpie/cli), used to
compare two coding-agent harnesses (**Codex** and **Pi**) driving the **same model
(GPT-5.5-high)** through one realistic, multi-capability task.

Base state is frozen at tag `bench-base` (httpie/cli master @ `5b604c3`).

## What we measure

For each harness, across two phases (plan, implement):

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

## Branch layout — one branch per tool

Two branches, both forked from `bench-base` so the start state is identical:

| Branch | Tool | Holds |
|--------|------|-------|
| `codex` | Codex | commit 1 = `PLAN.md` (plan deliverable), commit 2 = implementation |
| `pi`    | Pi    | commit 1 = `PLAN.md` (plan deliverable), commit 2 = implementation |

The two phases survive as the **two commits** on each branch — you still run (and
measure) the plan session and the implementation session separately, but each tool's
whole story lives on one branch. The committed `PLAN.md` is graded later from the
branch; the branch HEAD is graded by the hidden tests.

## How to run (per tool)

```bash
# ----- PLAN phase -----
git checkout codex && git reset --hard && git clean -fd
./benchmark/run_phase.sh codex plan      # inside the session type:  /plan
#   point it at benchmark/TASK.md, answer its questions from ANSWER_KEY.md,
#   have it save the plan to PLAN.md, exit, then:
git add PLAN.md && git commit -m "codex: plan"

# ----- IMPLEMENT phase (same branch) -----
./benchmark/run_phase.sh codex implement
#   prompt it to implement per TASK.md + ANSWER_KEY.md, exit, then:
git add -A && git commit -m "codex: implement"
git push -u origin codex
gh pr create --base bench-base --head codex --title "codex run" --body "benchmark"
```

Repeat the whole block on the `pi` branch with `/plannotator`. The plan step uses
each tool's **interactive** slash command (`/plan` in codex, `/plannotator` in pi) —
typed inside the running session. `run_phase.sh` checks you're on the right branch,
times the session, prompts you for token counts, and writes
`benchmark/metrics/<tool>-<phase>-<trial>.json` with cost filled in.

For extra trials, branch per trial off the tool branch's base, e.g.
`git checkout -b codex-trial2 bench-base` (then re-add the `benchmark/` scaffold or
branch from `codex` before its first commit).

Each invocation brackets the run with timestamps and writes a
`benchmark/metrics/<harness>-<phase>-<trial>.json` stub for you to fill from the
harness's own usage log.

**Run >=5 trials per harness per phase.** These agents are non-deterministic; report
median + range, never a single run.

## Fairness rules (do not skip)

1. Identical start: both tool branches fork from `bench-base`; reset clean before
   each phase.
2. Identical prompt (`TASK.md`) and identical answers (`ANSWER_KEY.md`).
3. Identical allowed tools + network policy + model sampling settings.
4. **Block the `github.com/httpie/cli` upstream domain** during runs so the agent
   can't find an upstream implementation. (Anti-contamination.)
5. Hidden acceptance tests live in a **separate private repo**
   (`sunith-v/httpie-sse-bench-hidden`), never here.
6. Grade blind: strip harness identifiers from diffs before scoring quality.

## Scoring

See [`SCORING.md`](SCORING.md).
