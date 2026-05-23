#!/bin/bash
# ============================================================
#  nim-claude-code / setup.sh
#  Run once to install everything you need
# ============================================================

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Claude Code + NVIDIA NIM  —  Setup     ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 1. Node.js ───────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  echo -e "${YELLOW}▸ Node.js not found. Installing via Homebrew...${NC}"
  if ! command -v brew &>/dev/null; then
    echo -e "${RED}✗ Homebrew not found. Install it first: https://brew.sh${NC}"
    exit 1
  fi
  brew install node
else
  echo -e "${GREEN}✓ Node.js $(node -v)${NC}"
fi

# ── 2. Claude Code ───────────────────────────────────────────
if ! command -v claude &>/dev/null; then
  echo -e "${YELLOW}▸ Installing Claude Code...${NC}"
  npm install -g @anthropic-ai/claude-code
else
  echo -e "${GREEN}✓ Claude Code $(claude --version 2>/dev/null || echo 'installed')${NC}"
fi

# ── 3. Python / pip ──────────────────────────────────────────
if ! command -v pip3 &>/dev/null; then
  echo -e "${YELLOW}▸ pip3 not found. Installing Python via Homebrew...${NC}"
  brew install python
else
  echo -e "${GREEN}✓ Python $(python3 --version)${NC}"
fi

# ── 4. LiteLLM (with proxy extras) ──────────────────────────
echo -e "${YELLOW}▸ Installing LiteLLM[proxy]...${NC}"
pip3 install 'litellm[proxy]' --quiet
echo -e "${GREEN}✓ LiteLLM[proxy] installed${NC}"

# ── 5. Write .env if missing ─────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/config/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo ""
  echo -e "${YELLOW}▸ No config/.env found. Let's create one.${NC}"
  echo ""
  read -p "  Paste your NVIDIA NIM API key (nvapi-...): " NIM_KEY
  echo ""
  echo "  Pick a model (press Enter for default):"
  echo "    1) meta/llama-3.3-70b-instruct            (default, best tool-use)"
  echo "    2) meta/llama-4-maverick-17b-128e-instruct (Llama 4 MoE)"
  echo "    3) mistralai/mistral-large-2-instruct      (large reasoning)"
  echo "    4) mistralai/codestral-22b-instruct-v0.1  (code-focused)"
  echo "    5) qwen/qwen3-coder-480b-a35b-instruct     (huge coder MoE)"
  echo "    6) deepseek-ai/deepseek-v4-pro             (strong coder)"
  echo "    7) Enter custom model ID"
  read -p "  Choice [1]: " MODEL_CHOICE

  case "$MODEL_CHOICE" in
    2) MODEL="meta/llama-4-maverick-17b-128e-instruct" ;;
    3) MODEL="mistralai/mistral-large-2-instruct" ;;
    4) MODEL="mistralai/codestral-22b-instruct-v0.1" ;;
    5) MODEL="qwen/qwen3-coder-480b-a35b-instruct" ;;
    6) MODEL="deepseek-ai/deepseek-v4-pro" ;;
    7) read -p "  Custom model ID: " MODEL ;;
    *) MODEL="meta/llama-3.3-70b-instruct" ;;
  esac

  mkdir -p "$SCRIPT_DIR/config"
  cat > "$ENV_FILE" <<ENVEOF
# NVIDIA NIM Configuration
# Edit this file to change your model or API key

NIM_API_KEY=${NIM_KEY}
MODEL_NAME=${MODEL}
PROXY_PORT=4000
ENVEOF
  echo ""
  echo -e "${GREEN}✓ Saved to config/.env${NC}"
else
  echo -e "${GREEN}✓ config/.env already exists${NC}"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Setup complete! Run ./start.sh to begin.  ${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
