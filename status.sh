#!/bin/bash
# ============================================================
#  nim-claude-code / status.sh
#  Check proxy health and show recent logs
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/config/.env"
PID_FILE="$SCRIPT_DIR/logs/proxy.pid"
LOG_FILE="$SCRIPT_DIR/logs/proxy.log"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Claude Code + NVIDIA NIM  —  Status    ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Config
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
  echo -e "  Model      : ${CYAN}${MODEL_NAME}${NC}"
  echo -e "  Proxy port : ${CYAN}${PROXY_PORT:-4000}${NC}"
  echo -e "  API key    : ${CYAN}${NIM_API_KEY:0:12}...${NC}"
else
  echo -e "  ${RED}✗ config/.env not found${NC}"
fi

echo ""

# Proxy process
if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  if kill -0 "$PID" 2>/dev/null; then
    echo -e "  Proxy      : ${GREEN}● Running (PID $PID)${NC}"
  else
    echo -e "  Proxy      : ${RED}✗ Not running (stale PID)${NC}"
  fi
else
  echo -e "  Proxy      : ${YELLOW}○ Not started${NC}"
fi

# HTTP health check
PORT="${PROXY_PORT:-4000}"
if curl -s "http://localhost:${PORT}/health" &>/dev/null; then
  echo -e "  Health     : ${GREEN}✓ Responding on :${PORT}${NC}"
else
  echo -e "  Health     : ${RED}✗ Not responding on :${PORT}${NC}"
fi

# Dependencies
echo ""
echo "  Dependencies:"
command -v node &>/dev/null   && echo -e "    ${GREEN}✓ Node.js $(node -v)${NC}"   || echo -e "    ${RED}✗ Node.js missing${NC}"
command -v claude &>/dev/null && echo -e "    ${GREEN}✓ Claude Code${NC}"           || echo -e "    ${RED}✗ Claude Code missing${NC}"
python3 -c "import litellm" &>/dev/null && echo -e "    ${GREEN}✓ LiteLLM${NC}"    || echo -e "    ${RED}✗ LiteLLM missing  →  run: pip3 install litellm[proxy]${NC}"

# Recent logs
if [ -f "$LOG_FILE" ]; then
  echo ""
  echo "  Last 10 proxy log lines:"
  echo "  ──────────────────────────────────────"
  tail -n 10 "$LOG_FILE" | sed 's/^/  /'
fi

echo ""
