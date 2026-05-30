#!/usr/bin/env bash
# Benchmark runner: times one harness on one phase and emits a metrics stub.
#
#   ./benchmark/run_phase.sh <harness> <phase> [trial]
#     harness : codex | pi
#     phase   : plan | result
#     trial   : integer, default 1
#
# This script does NOT invoke the harness for you (each harness has its own CLI).
# It (1) verifies you are on the right phase branch, (2) brackets the run with
# timestamps, (3) drops a metrics JSON stub for you to fill from the harness's own
# usage log. Replace the marked section with the actual harness invocation.

set -euo pipefail

HARNESS="${1:?usage: run_phase.sh <harness> <phase> [trial]}"
PHASE="${2:?usage: run_phase.sh <harness> <phase> [trial]}"
TRIAL="${3:-1}"

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

OUT="benchmark/metrics/${HARNESS}-${PHASE}-${TRIAL}.json"
START_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
START_S="$(date +%s)"

echo ">>> [$HARNESS / $PHASE / trial $TRIAL] started at $START_ISO"
echo ">>> branch: $BRANCH @ $(git rev-parse --short HEAD)"
echo ">>> Now drive the harness '$HARNESS' on benchmark/TASK.md."
echo ">>> When it finishes, press ENTER here to stop the clock."

# ----------------------------------------------------------------------------
# REPLACE THIS BLOCK with the real harness invocation, e.g.:
#   codex run --model gpt-5.5-high --prompt-file benchmark/TASK.md
#   pi    run --model gpt-5.5-high --task benchmark/TASK.md
# Leaving it interactive lets you drive the harness in another terminal.
read -r _ </dev/tty
# ----------------------------------------------------------------------------

END_S="$(date +%s)"
END_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
WALL=$(( END_S - START_S ))

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

  "_fill_from_harness_usage_log": "----- below: copy from the harness's own report -----",
  "input_tokens": null,
  "cached_input_tokens": null,
  "output_tokens": null,
  "reasoning_tokens": null,
  "tool_calls": null,
  "time_to_first_edit_s": null,

  "_computed_by_you": "----- compute from token counts x price sheet -----",
  "cost_usd": null
}
JSON

echo ">>> done in ${WALL}s. Stub written to $OUT — fill the null fields."
