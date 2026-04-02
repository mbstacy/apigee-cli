#!/usr/bin/env bash
# install.sh — Install apigee-cli and Claude Code /apigee-cli skill
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLI_SRC="$REPO_DIR/apigee-cli"
SKILL_SRC="$REPO_DIR/claude/apigee-cli.md"
CLI_DEST="$HOME/local/bin/apigee-cli"
SKILL_DEST="$HOME/.claude/commands/apigee-cli.md"
CONFIG_DEST="$HOME/.apigee-cli"

echo "Installing apigee-cli..."
echo ""

# 1. Install apigee-cli to ~/local/bin
mkdir -p "$(dirname "$CLI_DEST")"
cp "$CLI_SRC" "$CLI_DEST"
chmod +x "$CLI_DEST"
echo "  ✓ $CLI_DEST"

# 2. Install Claude Code /apigee-cli slash command
mkdir -p "$(dirname "$SKILL_DEST")"
cp "$SKILL_SRC" "$SKILL_DEST"
echo "  ✓ $SKILL_DEST"

# 3. Configure ~/.apigee-cli
if [[ -f "$CONFIG_DEST" ]]; then
  echo ""
  echo "  ✓ $CONFIG_DEST already exists (skipped)"
  echo "    To reconfigure, delete it and re-run this script."
else
  echo ""
  echo "Setting up Apigee configuration..."
  echo "Press Enter to skip any value and fill it in later."
  echo ""

  # --- Nonprod (dev / test / sand) ---
  echo "── Nonprod (dev, test, sand) ──"
  read -r -p "  Nonprod org name: " NONPROD_ORG
  read -r -p "  Nonprod SA key file path: " NONPROD_SA_KEY

  # --- Preprod (stage) ---
  echo ""
  echo "── Preprod (stage) ──"
  read -r -p "  Preprod org name [${NONPROD_ORG:-}]: " PREPROD_ORG
  PREPROD_ORG="${PREPROD_ORG:-$NONPROD_ORG}"
  read -r -p "  Preprod SA key file path [${NONPROD_SA_KEY:-}]: " PREPROD_SA_KEY
  PREPROD_SA_KEY="${PREPROD_SA_KEY:-$NONPROD_SA_KEY}"

  # --- Prod ---
  echo ""
  echo "── Prod ──"
  read -r -p "  Prod org name [${PREPROD_ORG:-}]: " PROD_ORG
  PROD_ORG="${PROD_ORG:-$PREPROD_ORG}"
  read -r -p "  Prod SA key file path [${PREPROD_SA_KEY:-}]: " PROD_SA_KEY
  PROD_SA_KEY="${PROD_SA_KEY:-$PREPROD_SA_KEY}"

  cat > "$CONFIG_DEST" <<EOF
# apigee-cli configuration
# Org names and service account key paths per environment.

DEV_ORG=${NONPROD_ORG:-}
DEV_SA_KEY=${NONPROD_SA_KEY:-}
TEST_ORG=${NONPROD_ORG:-}
TEST_SA_KEY=${NONPROD_SA_KEY:-}
SAND_ORG=${NONPROD_ORG:-}
SAND_SA_KEY=${NONPROD_SA_KEY:-}
STAGE_ORG=${PREPROD_ORG:-}
STAGE_SA_KEY=${PREPROD_SA_KEY:-}
PROD_ORG=${PROD_ORG:-}
PROD_SA_KEY=${PROD_SA_KEY:-}
EOF

  echo ""
  echo "  ✓ Created $CONFIG_DEST"

  # Warn about empty values
  if grep -q '=$' "$CONFIG_DEST" 2>/dev/null; then
    echo "  ⚠  Some values were left blank — edit $CONFIG_DEST to fill them in."
  fi
fi

echo ""
echo "Done. Make sure ~/local/bin is on your PATH:"
echo '  export PATH="$HOME/local/bin:$PATH"'
