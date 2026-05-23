#!/bin/bash
# ============================================================
#  nim-claude-code / switch-model.sh
#  Change the NIM model without re-running setup
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/config/.env"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

if [ ! -f "$ENV_FILE" ]; then
  echo "✗ config/.env not found. Run ./setup.sh first."
  exit 1
fi

source "$ENV_FILE"
echo ""
echo -e "  Current model: ${CYAN}${MODEL_NAME}${NC}"
echo ""
echo "  Pick a new model:"
echo "    1) meta/llama-3.3-70b-instruct          (recommended)"
echo "    2) meta/llama-4-maverick-17b-128e-instruct"
echo "    3) mistralai/mistral-large-2-instruct"
echo "    4) mistralai/codestral-22b-instruct-v0.1"
echo "    5) qwen/qwen3-coder-480b-a35b-instruct"
echo "    6) deepseek-ai/deepseek-v4-pro"
echo "    7) Enter custom model ID"
echo ""
read -p "  Choice: " CHOICE

case "$CHOICE" in
  1) NEW_MODEL="meta/llama-3.3-70b-instruct" ;;
  2) NEW_MODEL="meta/llama-4-maverick-17b-128e-instruct" ;;
  3) NEW_MODEL="mistralai/mistral-large-2-instruct" ;;
  4) NEW_MODEL="mistralai/codestral-22b-instruct-v0.1" ;;
  5) NEW_MODEL="qwen/qwen3-coder-480b-a35b-instruct" ;;
  6) NEW_MODEL="deepseek-ai/deepseek-v4-pro" ;;
  7) read -p "  Custom model ID: " NEW_MODEL ;;
  *) echo "Invalid choice."; exit 1 ;;
esac

sed -i '' "s|^MODEL_NAME=.*|MODEL_NAME=${NEW_MODEL}|" "$ENV_FILE"

echo ""
echo -e "${GREEN}✓ Model updated to: ${CYAN}${NEW_MODEL}${NC}"
echo -e "${YELLOW}  Restart with ./start.sh to apply.${NC}"
echo ""
