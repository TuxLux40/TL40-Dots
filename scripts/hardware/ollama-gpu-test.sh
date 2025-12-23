#!/usr/bin/env bash
set -euo pipefail

# Simple GPU/CPU usage test for Ollama on AMD ROCm
# - Runs a small model prompt
# - Parses recent logs / output to decide if ROCm GPU was used
# - Exits 0 when GPU acceleration detected, 1 otherwise
#
# Usage:
#   bash scripts/hardware/ollama-gpu-test.sh
# Options:
#   OGT_VERBOSE=1   # print matching log lines
#
# Notes:
# - Prefers an already-installed tiny model (qwen3:0.6b). If missing, attempts to pull it.
# - Works best if the systemd service "ollama.service" is active.

log() { printf "[ogt] %s\n" "$*"; }
err() { printf "[ogt:err] %s\n" "$*" 1>&2; }

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "Missing command: $1"
    exit 2
  fi
}

need ollama
need awk
need grep

MODEL="qwen3:0.6b"
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t ogt)"
RUN_OUT="$TMP_DIR/run.out"
JOUR_OUT="$TMP_DIR/journal.out"

cleanup() {
  rm -rf "$TMP_DIR" || true
}
trap cleanup EXIT

# Ensure the model exists or pull it (silent-ish)
if ! ollama list | awk 'NR>1 {print $1}' | grep -qx "$MODEL"; then
  log "Model $MODEL not found locally, attempting to pull (small download) ..."
  if ! ollama pull "$MODEL" >/dev/null 2>&1; then
    err "Failed to pull $MODEL. Install any small model manually and re-run."
    exit 3
  fi
fi

log "Running quick prompt on $MODEL ..."
# Capture stdout of the run; also make logs verbose for parsing fallback
export OLLAMA_LOG_LEVEL=debug
if ! timeout 60 ollama run "$MODEL" "Say: GPU test" >"$RUN_OUT" 2>&1; then
  err "ollama run failed (see $RUN_OUT)."
  # continue to parse whatever we got
fi

# Prefer journal logs (service logs contain the detailed backend selection)
if command -v journalctl >/dev/null 2>&1; then
  journalctl -u ollama.service -n 250 --no-pager -l >"$JOUR_OUT" 2>/dev/null || true
else
  : >"$JOUR_OUT"
fi

# Merge sources for detection (journal first, then run output)
ALL_OUT="$TMP_DIR/all.out"
cat "$JOUR_OUT" "$RUN_OUT" >"$ALL_OUT"

# Heuristics to detect GPU vs CPU usage
GPU_PATTERNS=(
  "loaded ROCm backend"
  "ggml_cuda_init: found .* ROCm devices"
  "library=ROCm"
  "compute=gfx[0-9]+"
  "offloaded .* layers to GPU"
  "device=ROCm[0-9]"
)
CPU_PATTERNS=(
  "loaded CPU backend"
)

GPU_HIT=0
for p in "${GPU_PATTERNS[@]}"; do
  if grep -Eiq "$p" "$ALL_OUT"; then
    GPU_HIT=1
    [ "${OGT_VERBOSE:-0}" = "1" ] && grep -Ein "$p" "$ALL_OUT" || true
  fi
done

if [ "$GPU_HIT" = "1" ]; then
  # Try to extract GFX IP and offload summary
  GFX=$(grep -Eio 'gfx[0-9]+' "$ALL_OUT" | head -n1 || true)
  OFFLOAD=$(grep -Eio 'offloaded [0-9]+/[0-9]+ layers to GPU' "$ALL_OUT" | tail -n1 || true)
  log "GPU acceleration: YES (ROCm) ${GFX:+| $GFX} ${OFFLOAD:+| $OFFLOAD}"
  exit 0
fi

# If no GPU signals found, check for explicit CPU lines
CPU_HIT=0
for p in "${CPU_PATTERNS[@]}"; do
  if grep -Eiq "$p" "$ALL_OUT"; then
    CPU_HIT=1
    [ "${OGT_VERBOSE:-0}" = "1" ] && grep -Ein "$p" "$ALL_OUT" || true
  fi
done

if [ "$CPU_HIT" = "1" ]; then
  err "GPU acceleration: NO (CPU backend detected)."
else
  err "GPU acceleration: UNKNOWN (no definitive signals found)."
fi

# Provide hints if discovery crashes are present
if grep -Eiq 'runner crashed|rocblas_abort|libggml-hip.so' "$ALL_OUT"; then
  err "Hint: ROCm discovery crash detected; consider setting HSA_OVERRIDE_GFX_VERSION and HSA_ENABLE_SDMA=0 for ollama.service."
fi

exit 1
