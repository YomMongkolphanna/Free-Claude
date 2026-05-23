#!/bin/bash
# ============================================================
#  nim-claude-code / start.sh
#  Starts the LiteLLM proxy then launches Claude Code
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/config/.env"
LOG_FILE="$SCRIPT_DIR/logs/proxy.log"
PID_FILE="$SCRIPT_DIR/logs/proxy.pid"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

# ── Load .env ────────────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
  echo -e "${RED}✗ config/.env not found. Run ./setup.sh first.${NC}"
  exit 1
fi
source "$ENV_FILE"

PROXY_PORT="${PROXY_PORT:-4000}"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Claude Code + NVIDIA NIM  —  Start     ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo -e "  Model : ${CYAN}${MODEL_NAME}${NC}"
echo -e "  Port  : ${CYAN}${PROXY_PORT}${NC}"
echo ""

# ── Kill old proxy if running ────────────────────────────────
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(cat "$PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo -e "${YELLOW}▸ Stopping previous proxy (PID $OLD_PID)...${NC}"
    kill "$OLD_PID" 2>/dev/null || true
    sleep 1
  fi
  rm -f "$PID_FILE"
fi

# ── Start LiteLLM proxy in background ───────────────────────
echo -e "${YELLOW}▸ Starting LiteLLM proxy...${NC}"
mkdir -p "$SCRIPT_DIR/logs"

# Generate per-run config (keeps model name dynamic)
cat > "$SCRIPT_DIR/config/litellm_runtime.yaml" <<EOF
model_list:
  - model_name: "${MODEL_NAME}"
    litellm_params:
      model: "nvidia_nim/${MODEL_NAME}"
      api_key: os.environ/NVIDIA_NIM_API_KEY

litellm_settings:
  drop_params: true
  num_retries: 0
  request_timeout: 120
  max_budget: null
EOF

NVIDIA_NIM_API_KEY="${NIM_API_KEY}" \
nohup litellm \
  --config "$SCRIPT_DIR/config/litellm_runtime.yaml" \
  --port "${PROXY_PORT}" \
  > "$LOG_FILE" 2>&1 &

PROXY_PID=$!
echo $PROXY_PID > "$PID_FILE"

# ── Wait for proxy to be ready ───────────────────────────────
echo -n "  Waiting for proxy"
for i in {1..40}; do
  if curl -s "http://localhost:${PROXY_PORT}/health" &>/dev/null; then
    echo ""
    echo -e "${GREEN}✓ Proxy ready (PID ${PROXY_PID})${NC}"
    break
  fi
  echo -n "."
  sleep 1
  if [ $i -eq 40 ]; then
    echo ""
    echo -e "${RED}✗ Proxy didn't start in time. Check logs/proxy.log${NC}"
    exit 1
  fi
done

# ── Export env vars for Claude Code ─────────────────────────
export ANTHROPIC_BASE_URL="http://localhost:${PROXY_PORT}"
export ANTHROPIC_API_KEY="not-used"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="${MODEL_NAME}"
export ANTHROPIC_DEFAULT_SONNET_MODEL="${MODEL_NAME}"
export ANTHROPIC_DEFAULT_OPUS_MODEL="${MODEL_NAME}"
export CLAUDE_CODE_SUBAGENT_MODEL="${MODEL_NAME}"
# Suppress auto-update noise (proxy key is not a real Anthropic key)
export DISABLE_AUTOUPDATER=1
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
# Limit Claude Code's requested output tokens to avoid context overflow with NIM models
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=4096

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Launching Claude Code...                  ${NC}"
echo -e "${GREEN}  (Ctrl+C or 'exit' to quit)                ${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ── Launch Claude Code ───────────────────────────────────────
claude

# ── Cleanup on exit ──────────────────────────────────────────
echo ""
echo -e "${YELLOW}▸ Stopping proxy (PID ${PROXY_PID})...${NC}"
kill "$PROXY_PID" 2>/dev/null || true
rm -f "$PID_FILE"
echo -e "${GREEN}✓ Done. Goodbye!${NC}"
echo ""
