#!/bin/bash
# ============================================================
#  nim-claude-code / stop.sh
#  Stops the LiteLLM proxy
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/logs/proxy.pid"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  if kill -0 "$PID" 2>/dev/null; then
    echo -e "${YELLOW}▸ Stopping proxy (PID $PID)...${NC}"
    kill "$PID"
    rm -f "$PID_FILE"
    echo -e "${GREEN}✓ Proxy stopped.${NC}"
  else
    echo -e "${YELLOW}▸ Proxy not running (stale PID file removed).${NC}"
    rm -f "$PID_FILE"
  fi
else
  # Try killing by port as fallback
  PORT=$(grep PROXY_PORT "$SCRIPT_DIR/config/.env" 2>/dev/null | cut -d= -f2 || echo "4000")
  PID=$(lsof -ti tcp:"$PORT" 2>/dev/null)
  if [ -n "$PID" ]; then
    echo -e "${YELLOW}▸ Killing process on port $PORT (PID $PID)...${NC}"
    kill "$PID"
    echo -e "${GREEN}✓ Stopped.${NC}"
  else
    echo -e "${GREEN}✓ No proxy running.${NC}"
  fi
fi
