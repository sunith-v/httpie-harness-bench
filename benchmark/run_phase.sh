#!/usr/bin/env bash
# Benchmark runner: launches one harness on one phase, times it, and emits a
# metrics record (cost auto-computed from token counts you paste in).
#
#   ./benchmark/run_phase.sh <harness> <phase> [trial]
#     harness : codex | pi
#     phase   : plan | result
#     trial   : integer, default 1
#
# The PLAN step in each tool is an INTERACTIVE slash command you type inside the
# session, not a shell flag:
#     codex -> type:  /plan
#     pi    -> type:  /plannotator
# For the RESULT phase, just give the tool benchmark/TASK.md and let it work.

set -euo pipefail

HARNESS="${1:?usage: run_phase.sh <harness> <phase> [trial]}"
PHASE="${2:?usage: run_phase.sh <harness> <phase> [trial]}"
TRIAL="${3:-1}"

# ---- GPT-5.5 pricing (USD per 1M tokens) -----------------------------------
PRICE_INPUT=5.0
PRICE_CACHED=0.5
PRICE_OUTPUT=30.0
# Reasoning tokens are billed as output for GPT-5.5.
PRICE_REASONING=30.0
# ----------------------------------------------------------------------------

case "$HARNESS" in
  codex) PLAN_CMD="/plan" ;;
  pi)    PLAN_CMD="/plannotator" ;;
  *) echo "harness must be 'codex' or 'pi'" >&2; exit 1 ;;
esac

case "$PHASE" in
  plan)   BRANCH="phase-1-plan" ;;
  result) BRANCH="phase-2-result" ;;
  *) echo "phase must be 'plan' or 'result'" >&2; exit 1 ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CUR="$(git rev-parse --abbrev-ref HEAD)"
if [ "$CUR" != "$BRANCH" ]; then
  echo "ERROR: expected branch '$BRANCH' for phase '$PHASE', but on '$CUR'." >&2
  echo "Run: git checkout $BRANCH" >&2
  exit 1
fi

if ! command -v "$HARNESS" >/dev/null 2>&1; then
  echo "ERROR: '$HARNESS' CLI not found on PATH. Install it first." >&2
  exit 1
fi

echo "============================================================"
echo " $HARNESS / $PHASE / trial $TRIAL   (branch $BRANCH @ $(git rev-parse --short HEAD))"
echo "------------------------------------------------------------"
echo " Task prompt: benchmark/TASK.md"
if [ "$PHASE" = "plan" ]; then
  echo " >>> Inside the session, type:   $PLAN_CMD"
  echo " >>> Paste/point it at benchmark/TASK.md, save the plan to PLAN.md."
else
  echo " >>> Give the tool benchmark/TASK.md and let it implement + open the PR."
fi
echo " Clock starts when the CLI launches; stops when you exit it."
echo "============================================================"

START_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
START_S="$(date +%s)"

# Launch the harness interactively. Exit the tool normally to stop the clock.
"$HARNESS" || true

END_S="$(date +%s)"
END_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
WALL=$(( END_S - START_S ))

echo
echo "Run finished in ${WALL}s. Now paste token counts from the harness usage log."
read -rp "  input_tokens        : " IN
read -rp "  cached_input_tokens : " CACHED
read -rp "  output_tokens       : " OUT_T
read -rp "  reasoning_tokens    : " REAS
read -rp "  tool_calls          : " TOOLS
IN="${IN:-0}"; CACHED="${CACHED:-0}"; OUT_T="${OUT_T:-0}"; REAS="${REAS:-0}"; TOOLS="${TOOLS:-0}"

COST=$(awk -v i="$IN" -v c="$CACHED" -v o="$OUT_T" -v r="$REAS" \
  -v pi="$PRICE_INPUT" -v pc="$PRICE_CACHED" -v po="$PRICE_OUTPUT" -v pr="$PRICE_REASONING" \
  'BEGIN { printf "%.6f", (i*pi + c*pc + o*po + r*pr) / 1000000.0 }')

OUT="benchmark/metrics/${HARNESS}-${PHASE}-${TRIAL}.json"
mkdir -p benchmark/metrics
cat > "$OUT" <<JSON
{
  "harness": "$HARNESS",
  "phase": "$PHASE",
  "trial": $TRIAL,
  "model": "gpt-5.5-high",
  "branch": "$BRANCH",
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
