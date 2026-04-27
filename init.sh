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
BLUE='\033[0;34m'h
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${PURPLE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   MAOS Machine — Pipeline Autonome Multi-Agents ║${NC}"h
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

# Stack technique
echo -e "${YELLOW}Stack technique${NC} (ex: Next.js + NestJS + Prisma + PostgreSQL, ou Entree pour auto-detect) :"
read -p "> " STACK_INFO
STACK_INFO="${STACK_INFO:-Auto-detecte par les agents au premier scan}"

# VISION DU PROJET — le plus important
echo ""
echo -e "${CYAN}━━━ VISION DU PROJET (le plus important) ━━━${NC}"
echo -e "${YELLOW}Decris ton projet en quelques lignes.${NC}"
echo -e "${YELLOW}C'est ce que le Stratege lira pour creer les taches.${NC}"
echo -e "${YELLOW}(Tape ta vision, puis une ligne vide pour terminer)${NC}"
echo ""
VISION=""
while IFS= read -r line; do
  [ -z "$line" ] && break
  VISION="${VISION}${line}\n"
done

if [ -z "$VISION" ]; then
  VISION="Projet a definir. Le stratege doit auditer le code existant et proposer un plan."
fi

echo ""
echo -e "${GREEN}Configuration recue. Installation...${NC}"
echo ""

# ============================================================
# 0b. Installer /machine globalement (auto)
# ============================================================
echo -e "${GREEN}[0/8] Installation commande /machine globale...${NC}"
mkdir -p "$HOME/.claude/commands"
cp "$TEMPLATE_DIR/.claude/commands/machine.md" "$HOME/.claude/commands/machine.md"
echo -e "  ${GREEN}✓${NC} /machine disponible dans TOUS tes projets"

# ============================================================
# 2. Structure pipeline
# ============================================================
echo -e "${GREEN}[1/8] Pipeline...${NC}"

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
      -e "s|___PROJECT_DESCRIPTION___|$(echo -e "$VISION" | head -1)|g" \
      -e "s|___STACK___|$STACK_INFO|g" \
      "$TEMPLATE_DIR/CLAUDE.md.template" > "$TARGET/CLAUDE.md"

  # Ajouter la vision complete dans CLAUDE.md
  cat >> "$TARGET/CLAUDE.md" << VISIONEOF

---

## VISION DU FONDATEUR

$(echo -e "$VISION")

**C'est la directive principale. Le stratege doit creer des taches a partir de cette vision.
Le designer doit specifier l'UI/UX selon cette vision.
Le code-dev doit implementer selon cette vision.**

VISIONEOF

  echo -e "  ${GREEN}✓${NC} CLAUDE.md genere avec la vision du projet"
fi

# ============================================================
# 7. Premiere tache — le stratege sait quoi faire
# ============================================================
echo -e "${GREEN}[6/8] Premiere tache backlog...${NC}"

cat > "$TARGET/.maos-pipeline/backlog/001_initialisation-projet.md" << TASKEOF
# 001 — Initialisation du projet $PROJECT_NAME

**Priorite** : CRITIQUE
**Creee par** : init.sh (automatique)
**Assignee a** : stratege

## Contexte

Ce projet vient d'etre initialise par MAOS Machine.
Le fondateur a decrit sa vision dans CLAUDE.md (section "VISION DU FONDATEUR").

## Instructions pour le Stratege

1. **Lire CLAUDE.md** en entier — comprendre la vision du fondateur
2. **Auditer le code existant** (s'il y en a) :
   - Structure des dossiers
   - Stack detectee
   - Fichiers existants
   - package.json si present
3. **Creer le PLAN.md** avec la direction du sprint
4. **Creer les ZONES.md** avec la carte des territoires
5. **Decomposer la vision** en taches concretes dans backlog/ :
   - Architecture (P0)
   - Design system (P0)
   - Backend structure (P0)
   - Frontend structure (P0)
   - Puis features par ordre de priorite
6. **Creer les taches DESIGN** pour le designer
7. **Specifier chaque tache** avec fichiers concernes exacts

## Vision du fondateur

$(echo -e "$VISION")

## Criteres de validation

- PLAN.md cree
- ZONES.md cree
- Au moins 5 taches dans backlog/
- Chaque tache a des fichiers concernes specifiques
- Les taches sont dans l'ordre de priorite correct

---
## Rapport code-dev
(non applicable — tache stratege)

## Audit testeur
(non applicable — tache stratege)
TASKEOF

echo -e "  ${GREEN}✓${NC} Tache 001 creee dans backlog/ (le stratege demarre immediatement)"

# ============================================================
# 8. .gitignore
# ============================================================
echo -e "${GREEN}[7/8] .gitignore...${NC}"

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
echo -e "${GREEN}[8/8] Script de demarrage...${NC}"

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
start "CHEF" cmd /k "cd /d $TARGET_BAT && (echo /loop 450s /chef) | claude --dangerously-skip-permissions --model claude-opus-4-7"
timeout /t 3 /nobreak >nul

echo  [2] Lancement du Stratege...
start "STRATEGE" cmd /k "cd /d $TARGET_BAT && (echo /loop 900s /stratege) | claude --dangerously-skip-permissions --model claude-opus-4-7"
timeout /t 2 /nobreak >nul

BATEOF

# Ajouter N code-dev
for i in $(seq 1 $NUM_CODEDEV); do
  NUM=$((i + 2))
cat >> "$TARGET/start-machine.bat" << BATEOF
echo  [$NUM] Lancement Code-Dev $i...
start "CODE-DEV-$i" cmd /k "cd /d $TARGET_BAT && (echo /loop 600s /code-dev) | claude --dangerously-skip-permissions --model claude-opus-4-7"
timeout /t 2 /nobreak >nul

BATEOF
done

NEXT=$((NUM_CODEDEV + 3))
cat >> "$TARGET/start-machine.bat" << BATEOF
echo  [$NEXT] Lancement du Testeur...
start "TESTEUR" cmd /k "cd /d $TARGET_BAT && (echo /loop 900s /testeur) | claude --dangerously-skip-permissions --model claude-sonnet-4-5"
timeout /t 2 /nobreak >nul

echo  [$((NEXT+1))] Lancement du DevOps...
start "DEVOPS" cmd /k "cd /d $TARGET_BAT && (echo /loop 900s /devops) | claude --dangerously-skip-permissions --model claude-sonnet-4-5"
timeout /t 2 /nobreak >nul

echo  [$((NEXT+2))] Lancement du Designer...
start "DESIGNER" cmd /k "cd /d $TARGET_BAT && (echo /loop 900s /designer) | claude --dangerously-skip-permissions --model claude-opus-4-7"
timeout /t 2 /nobreak >nul

echo  [$((NEXT+3))] Lancement du Veilleur Tech...
start "VEILLEUR-TECH" cmd /k "cd /d $TARGET_BAT && (echo /loop 604800s /veilleur-tech) | claude --dangerously-skip-permissions --model claude-sonnet-4-5"

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
