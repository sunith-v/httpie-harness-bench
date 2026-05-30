#!/usr/bin/env bash
# Benchmark runner: launches one tool for one phase, times it, and writes a
# metrics record (cost auto-computed from the token counts you paste in).
#
#   ./benchmark/run_phase.sh <tool> <phase> [trial]
#     tool  : codex | pi      (also the branch you must be on)
#     phase : plan | implement
#     trial : integer, default 1
#
# Branch layout: one branch per tool (`codex`, `pi`), both forked from bench-base.
# The plan phase produces PLAN.md (commit 1); the implement phase produces the
# code (commit 2). The PLAN step is an INTERACTIVE slash command you type inside
# the session, not a shell flag:
#     codex -> /plan        pi -> /plannotator

set -euo pipefail

TOOL="${1:?usage: run_phase.sh <tool> <phase> [trial]}"
PHASE="${2:?usage: run_phase.sh <tool> <phase> [trial]}"
TRIAL="${3:-1}"

# ---- GPT-5.5 pricing (USD per 1M tokens) -----------------------------------
PRICE_INPUT=5.0
PRICE_CACHED=0.5
PRICE_OUTPUT=30.0
PRICE_REASONING=30.0   # reasoning billed as output
# ----------------------------------------------------------------------------

case "$TOOL" in
  codex) PLAN_CMD="/plan"; LAUNCH=(codex -m gpt-5.5 -c model_reasoning_effort=high) ;;
  pi)    PLAN_CMD="/plannotator"; LAUNCH=(pi --model "openai/gpt-5.5:high") ;;
  *) echo "tool must be 'codex' or 'pi'" >&2; exit 1 ;;
esac

case "$PHASE" in
  plan|implement) ;;
  *) echo "phase must be 'plan' or 'implement'" >&2; exit 1 ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CUR="$(git rev-parse --abbrev-ref HEAD)"
if [ "$CUR" != "$TOOL" ]; then
  echo "ERROR: expected to be on branch '$TOOL', but on '$CUR'." >&2
  echo "Run: git checkout $TOOL && git reset --hard && git clean -fd" >&2
  exit 1
fi

if ! command -v "$TOOL" >/dev/null 2>&1; then
  echo "ERROR: '$TOOL' CLI not found on PATH." >&2
  exit 1
fi

echo "============================================================"
echo " $TOOL / $PHASE / trial $TRIAL   (branch $TOOL @ $(git rev-parse --short HEAD))"
echo "------------------------------------------------------------"
echo " Task prompt: benchmark/TASK.md     Answers: benchmark/ANSWER_KEY.md"
if [ "$PHASE" = "plan" ]; then
  echo " >>> Inside the session type:  $PLAN_CMD"
  echo " >>> Point it at benchmark/TASK.md; answer its questions from ANSWER_KEY.md."
  echo " >>> Have it SAVE the plan to PLAN.md, then exit."
  echo " >>> Afterwards:  git add PLAN.md && git commit -m '$TOOL: plan'"
else
  echo " >>> Prompt it to implement per TASK.md + ANSWER_KEY.md, then exit."
  echo " >>> Afterwards:  git add -A && git commit -m '$TOOL: implement' && git push -u origin $TOOL"
fi
echo " Clock starts when the CLI launches; stops when you exit it."
echo "============================================================"

START_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
START_S="$(date +%s)"

"${LAUNCH[@]}" || true

END_S="$(date +%s)"
END_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
WALL=$(( END_S - START_S ))

echo
echo "Run finished in ${WALL}s. Paste token counts from the tool's usage log"
echo "(codex: /status before exiting;  pi: end-of-run summary or --mode json)."
read -rp "  input_tokens        : " IN
read -rp "  cached_input_tokens : " CACHED
read -rp "  output_tokens       : " OUT_T
read -rp "  reasoning_tokens    : " REAS
read -rp "  tool_calls          : " TOOLS
IN="${IN:-0}"; CACHED="${CACHED:-0}"; OUT_T="${OUT_T:-0}"; REAS="${REAS:-0}"; TOOLS="${TOOLS:-0}"

COST=$(awk -v i="$IN" -v c="$CACHED" -v o="$OUT_T" -v r="$REAS" \
  -v pi="$PRICE_INPUT" -v pc="$PRICE_CACHED" -v po="$PRICE_OUTPUT" -v pr="$PRICE_REASONING" \
  'BEGIN { printf "%.6f", (i*pi + c*pc + o*po + r*pr) / 1000000.0 }')

OUT="benchmark/metrics/${TOOL}-${PHASE}-${TRIAL}.json"
mkdir -p benchmark/metrics
cat > "$OUT" <<JSON
{
  "tool": "$TOOL",
  "phase": "$PHASE",
  "trial": $TRIAL,
  "model": "gpt-5.5-high",
  "branch": "$TOOL",
  "base_sha": "$(git rev-parse HEAD)",
  "started_at": "$START_ISO",
  "ended_at": "$END_ISO",
  "wall_clock_s": $WALL,
  "input_tokens": $IN,
  "cached_input_tokens": $CACHED,
  "output_tokens": $OUT_T,
  "reasoning_tokens": $REAS,
  "tool_calls": $TOOLS,
  "pricing_usd_per_1m": { "input": $PRICE_INPUT, "cached": $PRICE_CACHED, "output": $PRICE_OUTPUT },
  "cost_usd": $COST
}
JSON

echo "Wrote $OUT  (cost = \$$COST)"
