#!/bin/bash
# ============================================================
# MAOS Machine — Initialisation AUTOMATIQUE Pipeline Autonome
# ============================================================
# Usage: bash init.sh [chemin-du-projet]
# Tout est automatique. Le script demande les infos et configure tout.
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${PURPLE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   MAOS Machine — Pipeline Autonome Multi-Agents ║${NC}"
echo -e "${PURPLE}║   Installation 100% automatique                 ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================
# 0. Cible
# ============================================================
TARGET="${1:-.}"
TARGET=$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/template"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo -e "${RED}ERREUR: template/ introuvable dans $SCRIPT_DIR${NC}"
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  mkdir -p "$TARGET"
fi

if [ -d "$TARGET/.maos-pipeline" ]; then
  echo -e "${YELLOW}Pipeline deja installee. Reinitialiser ? (o/N)${NC}"
  read -p "> " -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Oo]$ ]] && exit 0
fi

echo -e "${BLUE}Projet : ${NC}$TARGET"
PROJECT_NAME=$(basename "$TARGET")
echo ""

# ============================================================
# 1. Collecte des infos (interactif)
# ============================================================
echo -e "${CYAN}━━━ Configuration rapide (Entree = skip/optionnel) ━━━${NC}"
echo ""

# Sentry
echo -e "${YELLOW}Sentry auth token${NC} (sntrys_... ou Entree pour skip) :"
read -p "> " SENTRY_TOKEN
SENTRY_TOKEN="${SENTRY_TOKEN:-__SKIP__}"

if [ "$SENTRY_TOKEN" != "__SKIP__" ]; then
  echo -e "${YELLOW}Sentry org slug${NC} (ex: maos-software) :"
  read -p "> " SENTRY_ORG
  SENTRY_ORG="${SENTRY_ORG:-my-org}"
else
  SENTRY_ORG="__SKIP__"
fi

# Database
echo -e "${YELLOW}Database URL${NC} (postgresql://user:pass@host:port/db ou Entree pour skip) :"
read -p "> " DB_URL
DB_URL="${DB_URL:-__SKIP__}"

# 21st.dev API key
echo -e "${YELLOW}21st.dev API key${NC} (pour magic components, ou Entree pour skip) :"
read -p "> " TWENTY_FIRST_KEY
TWENTY_FIRST_KEY="${TWENTY_FIRST_KEY:-__SKIP__}"

# Nombre de code-dev
echo -e "${YELLOW}Combien de code-dev en parallele ?${NC} (defaut: 2) :"
read -p "> " NUM_CODEDEV
NUM_CODEDEV="${NUM_CODEDEV:-2}"

echo ""
echo -e "${GREEN}Configuration recue. Installation...${NC}"
echo ""

# ============================================================
# 2. Structure pipeline
# ============================================================
echo -e "${GREEN}[1/7] Pipeline...${NC}"

DIRS=("backlog" "in-progress" "review" "done" "blocked" "deployed" "incidents" "checkpoints" "locks" "archived-v1")
for dir in "${DIRS[@]}"; do
  mkdir -p "$TARGET/.maos-pipeline/$dir"
  touch "$TARGET/.maos-pipeline/$dir/.gitkeep"
done
cp "$TEMPLATE_DIR/.maos-pipeline/README.md" "$TARGET/.maos-pipeline/README.md"
echo -e "  ${GREEN}✓${NC} 10 dossiers"

# ============================================================
# 3. Agents
# ============================================================
echo -e "${GREEN}[2/7] Agents...${NC}"

mkdir -p "$TARGET/.claude/commands"
AGENTS=("chef" "stratege" "code-dev" "testeur" "devops" "designer" "veilleur-tech" "auto-repair")
for agent in "${AGENTS[@]}"; do
  cp "$TEMPLATE_DIR/.claude/commands/${agent}.md" "$TARGET/.claude/commands/${agent}.md"
done
echo -e "  ${GREEN}✓${NC} 8 agents installes"

# ============================================================
# 4. MCP — auto-configure
# ============================================================
echo -e "${GREEN}[3/7] MCP (auto-config)...${NC}"

[ -f "$TARGET/.mcp.json" ] && cp "$TARGET/.mcp.json" "$TARGET/.mcp.json.bak"

# Convertir le chemin pour Windows (backslashes doubles pour JSON)
TARGET_WIN=$(echo "$TARGET" | sed 's|/|\\\\|g' | sed 's|^\\\\c\\\\|C:\\\\|')

# Construire le .mcp.json avec les vraies valeurs
cat > "$TARGET/.mcp.json" << MCPEOF
{
  "mcpServers": {
    "fetch": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@anthropic-ai/mcp-fetch@latest"]
    },
    "filesystem": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@anthropic-ai/mcp-filesystem@latest", "$TARGET_WIN"]
    },
    "chrome-devtools": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@anthropic-ai/mcp-chrome-devtools@latest"]
    },
    "magic-ui": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@nicholasoxford/magic-ui-mcp@latest"]
    },
    "ui-ux-pro": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "ui-ux-pro-mcp@latest"]
    },
    "shadcn-ui": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "shadcn-ui-mcp@latest"]
    },
    "playwright": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@anthropic-ai/mcp-playwright@latest"]
    },
    "memory": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@anthropic-ai/mcp-memory@latest"]
    }
MCPEOF

# Ajouter Sentry si fourni
if [ "$SENTRY_TOKEN" != "__SKIP__" ]; then
cat >> "$TARGET/.mcp.json" << MCPEOF
    ,"sentry": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@anthropic-ai/mcp-sentry@latest"],
      "env": {
        "SENTRY_AUTH_TOKEN": "$SENTRY_TOKEN",
        "SENTRY_ORG": "$SENTRY_ORG"
      }
    }
MCPEOF
fi

# Ajouter Postgres si fourni
if [ "$DB_URL" != "__SKIP__" ]; then
cat >> "$TARGET/.mcp.json" << MCPEOF
    ,"postgres": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@anthropic-ai/mcp-postgres@latest", "$DB_URL"]
    }
MCPEOF
fi

# Ajouter 21st-magic si fourni
if [ "$TWENTY_FIRST_KEY" != "__SKIP__" ]; then
cat >> "$TARGET/.mcp.json" << MCPEOF
    ,"21st-magic": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "21st-magic-mcp@latest"],
      "env": {
        "TWENTY_FIRST_API_KEY": "$TWENTY_FIRST_KEY"
      }
    }
MCPEOF
fi

# Fermer le JSON
echo "  }" >> "$TARGET/.mcp.json"
echo "}" >> "$TARGET/.mcp.json"

echo -e "  ${GREEN}✓${NC} .mcp.json configure automatiquement"

# ============================================================
# 5. Settings
# ============================================================
echo -e "${GREEN}[4/7] Permissions...${NC}"

mkdir -p "$TARGET/.claude"
[ -f "$TARGET/.claude/settings.local.json" ] && cp "$TARGET/.claude/settings.local.json" "$TARGET/.claude/settings.local.json.bak"
cp "$TEMPLATE_DIR/.claude/settings.local.json" "$TARGET/.claude/settings.local.json"
echo -e "  ${GREEN}✓${NC} settings.local.json"

# ============================================================
# 6. CLAUDE.md
# ============================================================
echo -e "${GREEN}[5/7] CLAUDE.md...${NC}"

if [ -f "$TARGET/CLAUDE.md" ]; then
  echo -e "  ${YELLOW}⚠ existe deja — conserve${NC}"
else
  DATE=$(date +%Y-%m-%d)
  sed -e "s/___DATE___/$DATE/g" \
      -e "s/___PROJECT_NAME___/$PROJECT_NAME/g" \
      -e "s/___AUTHOR___/mOOn/g" \
      -e "s/___PROJECT_DESCRIPTION___/Projet configure par MAOS Machine/g" \
      -e "s/___STACK___/Auto-detecte par les agents/g" \
      "$TEMPLATE_DIR/CLAUDE.md.template" > "$TARGET/CLAUDE.md"
  echo -e "  ${GREEN}✓${NC} CLAUDE.md genere"
fi

# ============================================================
# 7. .gitignore
# ============================================================
echo -e "${GREEN}[6/7] .gitignore...${NC}"

GITIGNORE_LINES=("# MAOS Machine" ".maos-pipeline/locks/*" "!.maos-pipeline/locks/.gitkeep")
if [ -f "$TARGET/.gitignore" ]; then
  for line in "${GITIGNORE_LINES[@]}"; do
    grep -qF "$line" "$TARGET/.gitignore" 2>/dev/null || echo "$line" >> "$TARGET/.gitignore"
  done
else
  printf '%s\n' "${GITIGNORE_LINES[@]}" > "$TARGET/.gitignore"
fi
echo -e "  ${GREEN}✓${NC} .gitignore"

# ============================================================
# 8. Script de demarrage automatique
# ============================================================
echo -e "${GREEN}[7/7] Script de demarrage...${NC}"

# Convertir le path pour Windows batch
TARGET_BAT=$(echo "$TARGET" | sed 's|/|\\|g' | sed 's|^\\c\\|C:\\|')

cat > "$TARGET/start-machine.bat" << BATEOF
@echo off
title MAOS Machine — Lanceur
color 0A

echo.
echo  ╔══════════════════════════════════════════════╗
echo  ║   MAOS Machine — Demarrage automatique      ║
echo  ╚══════════════════════════════════════════════╝
echo.

cd /d "$TARGET_BAT"

echo  [1] Lancement du Chef d'Orchestre...
start "CHEF" cmd /k "cd /d $TARGET_BAT && claude -p \"/loop 120 /chef\""
timeout /t 3 /nobreak >nul

echo  [2] Lancement du Stratege...
start "STRATEGE" cmd /k "cd /d $TARGET_BAT && claude -p \"/loop 600 /stratege\""
timeout /t 2 /nobreak >nul

BATEOF

# Ajouter N code-dev
for i in $(seq 1 $NUM_CODEDEV); do
  NUM=$((i + 2))
cat >> "$TARGET/start-machine.bat" << BATEOF
echo  [$NUM] Lancement Code-Dev $i...
start "CODE-DEV-$i" cmd /k "cd /d $TARGET_BAT && claude -p \"/loop 600 /code-dev\""
timeout /t 2 /nobreak >nul

BATEOF
done

NEXT=$((NUM_CODEDEV + 3))
cat >> "$TARGET/start-machine.bat" << BATEOF
echo  [$NEXT] Lancement du Testeur...
start "TESTEUR" cmd /k "cd /d $TARGET_BAT && claude -p \"/loop 600 /testeur\""
timeout /t 2 /nobreak >nul

echo  [$((NEXT+1))] Lancement du DevOps...
start "DEVOPS" cmd /k "cd /d $TARGET_BAT && claude -p \"/loop 600 /devops\""
timeout /t 2 /nobreak >nul

echo  [$((NEXT+2))] Lancement du Designer...
start "DESIGNER" cmd /k "cd /d $TARGET_BAT && claude -p \"/loop 600 /designer\""
timeout /t 2 /nobreak >nul

echo  [$((NEXT+3))] Lancement du Veilleur Tech...
start "VEILLEUR-TECH" cmd /k "cd /d $TARGET_BAT && claude -p \"/loop 600 /veilleur-tech\""

echo.
echo  ══════════════════════════════════════════════
echo  MACHINE DEMARREE — $((NEXT+3)) agents actifs
echo  ══════════════════════════════════════════════
echo.
echo  Pour arreter : fermer les fenetres ou taper "stop" dans chaque terminal
echo.
pause
BATEOF

# Script stop
cat > "$TARGET/stop-machine.bat" << BATEOF
@echo off
title MAOS Machine — Arret
echo.
echo  Arret de tous les agents Claude Code...
echo.
taskkill /FI "WINDOWTITLE eq CHEF*" /F 2>nul
taskkill /FI "WINDOWTITLE eq STRATEGE*" /F 2>nul
taskkill /FI "WINDOWTITLE eq CODE-DEV*" /F 2>nul
taskkill /FI "WINDOWTITLE eq TESTEUR*" /F 2>nul
taskkill /FI "WINDOWTITLE eq DEVOPS*" /F 2>nul
taskkill /FI "WINDOWTITLE eq DESIGNER*" /F 2>nul
taskkill /FI "WINDOWTITLE eq VEILLEUR*" /F 2>nul
echo.
echo  Nettoyage des locks...
rd /s /q "$TARGET_BAT\\.maos-pipeline\\locks" 2>nul
mkdir "$TARGET_BAT\\.maos-pipeline\\locks" 2>nul
echo. > "$TARGET_BAT\\.maos-pipeline\\locks\\.gitkeep"
echo.
echo  Machine arretee.
pause
BATEOF

echo -e "  ${GREEN}✓${NC} start-machine.bat (double-clic pour demarrer)"
echo -e "  ${GREEN}✓${NC} stop-machine.bat (double-clic pour arreter)"

# ============================================================
# Resume final
# ============================================================
echo ""
echo -e "${PURPLE}══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  INSTALLATION TERMINEE — TOUT EST CONFIGURE${NC}"
echo -e "${PURPLE}══════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Projet        : $TARGET"
echo -e "  Agents        : 8 (chef + stratege + ${NUM_CODEDEV} code-dev + testeur + devops + designer + veilleur)"
echo -e "  MCP           : $([ "$SENTRY_TOKEN" != "__SKIP__" ] && echo "sentry + ")$([ "$DB_URL" != "__SKIP__" ] && echo "postgres + ")$([ "$TWENTY_FIRST_KEY" != "__SKIP__" ] && echo "21st-magic + ")fetch + filesystem + chrome + magic-ui + shadcn + ui-ux-pro + playwright + memory"
echo ""
echo -e "  ${GREEN}▶ DEMARRER :${NC} double-clic sur ${CYAN}start-machine.bat${NC}"
echo -e "  ${RED}■ ARRETER  :${NC} double-clic sur ${CYAN}stop-machine.bat${NC}"
echo ""
echo -e "${GREEN}C'est tout. La machine tourne.${NC}"
echo ""
