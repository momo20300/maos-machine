#!/bin/bash
# ============================================================
# MAOS Machine — Initialisation Pipeline Autonome 6 Agents
# ============================================================
# Usage: bash init.sh [chemin-du-projet]
#
# Ce script installe la pipeline autonome dans n'importe quel
# projet existant. Il cree la structure, copie les agents,
# configure les MCP, et genere le CLAUDE.md.
#
# Prerequis:
#   - Node.js >= 18
#   - Git
#   - Claude Code CLI installe
# ============================================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Banner
echo ""
echo -e "${PURPLE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   MAOS Machine — Pipeline Autonome 6 Agents ║${NC}"
echo -e "${PURPLE}║   by mOOn — MAOS Software Ltd               ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Chemin du projet cible
TARGET="${1:-.}"
TARGET=$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")

# Chemin du template (relatif au script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/template"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo -e "${RED}ERREUR: dossier template/ introuvable dans $SCRIPT_DIR${NC}"
  exit 1
fi

echo -e "${BLUE}Projet cible: ${NC}$TARGET"
echo ""

# Verifier que le dossier cible existe
if [ ! -d "$TARGET" ]; then
  echo -e "${YELLOW}Le dossier $TARGET n'existe pas. Creation...${NC}"
  mkdir -p "$TARGET"
fi

# Verifier si deja initialise
if [ -d "$TARGET/.maos-pipeline" ]; then
  echo -e "${YELLOW}ATTENTION: .maos-pipeline existe deja dans ce projet.${NC}"
  read -p "Voulez-vous reinitialiser ? (o/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Oo]$ ]]; then
    echo -e "${RED}Abandon.${NC}"
    exit 0
  fi
fi

# ============================================================
# 1. Structure pipeline
# ============================================================
echo -e "${GREEN}[1/6] Creation de la structure pipeline...${NC}"

DIRS=(
  ".maos-pipeline/backlog"
  ".maos-pipeline/in-progress"
  ".maos-pipeline/review"
  ".maos-pipeline/done"
  ".maos-pipeline/blocked"
  ".maos-pipeline/deployed"
  ".maos-pipeline/incidents"
  ".maos-pipeline/checkpoints"
  ".maos-pipeline/locks"
  ".maos-pipeline/archived-v1"
)

for dir in "${DIRS[@]}"; do
  mkdir -p "$TARGET/$dir"
  touch "$TARGET/$dir/.gitkeep"
done

cp "$TEMPLATE_DIR/.maos-pipeline/README.md" "$TARGET/.maos-pipeline/README.md"
echo -e "  ${GREEN}✓${NC} 10 dossiers pipeline crees"

# ============================================================
# 2. Agents (skills)
# ============================================================
echo -e "${GREEN}[2/6] Installation des 7 agents + auto-repair...${NC}"

mkdir -p "$TARGET/.claude/commands"

AGENTS=("stratege" "code-dev" "testeur" "devops" "designer" "veilleur-tech" "auto-repair")
for agent in "${AGENTS[@]}"; do
  cp "$TEMPLATE_DIR/.claude/commands/${agent}.md" "$TARGET/.claude/commands/${agent}.md"
  echo -e "  ${GREEN}✓${NC} ${agent}.md installe"
done

# ============================================================
# 3. MCP Configuration
# ============================================================
echo -e "${GREEN}[3/6] Configuration MCP...${NC}"

if [ -f "$TARGET/.mcp.json" ]; then
  echo -e "  ${YELLOW}⚠ .mcp.json existe deja — sauvegarde dans .mcp.json.bak${NC}"
  cp "$TARGET/.mcp.json" "$TARGET/.mcp.json.bak"
fi

cp "$TEMPLATE_DIR/.mcp.json" "$TARGET/.mcp.json"
echo -e "  ${GREEN}✓${NC} .mcp.json installe (11 MCP servers)"

# ============================================================
# 4. Settings
# ============================================================
echo -e "${GREEN}[4/6] Configuration permissions...${NC}"

mkdir -p "$TARGET/.claude"

if [ -f "$TARGET/.claude/settings.local.json" ]; then
  echo -e "  ${YELLOW}⚠ settings.local.json existe — sauvegarde dans settings.local.json.bak${NC}"
  cp "$TARGET/.claude/settings.local.json" "$TARGET/.claude/settings.local.json.bak"
fi

cp "$TEMPLATE_DIR/.claude/settings.local.json" "$TARGET/.claude/settings.local.json"
echo -e "  ${GREEN}✓${NC} settings.local.json installe"

# ============================================================
# 5. CLAUDE.md
# ============================================================
echo -e "${GREEN}[5/6] Generation CLAUDE.md...${NC}"

if [ -f "$TARGET/CLAUDE.md" ]; then
  echo -e "  ${YELLOW}⚠ CLAUDE.md existe deja — le template est copie en CLAUDE.md.template${NC}"
  cp "$TEMPLATE_DIR/CLAUDE.md.template" "$TARGET/CLAUDE.md.template"
else
  DATE=$(date +%Y-%m-%d)
  PROJECT_NAME=$(basename "$TARGET")

  sed -e "s/___DATE___/$DATE/g" \
      -e "s/___PROJECT_NAME___/$PROJECT_NAME/g" \
      -e "s/___AUTHOR___/mOOn/g" \
      -e "s/___PROJECT_DESCRIPTION___/A remplir/g" \
      -e "s/___STACK___/A remplir/g" \
      "$TEMPLATE_DIR/CLAUDE.md.template" > "$TARGET/CLAUDE.md"
  echo -e "  ${GREEN}✓${NC} CLAUDE.md genere (a personnaliser)"
fi

# ============================================================
# 6. .gitignore
# ============================================================
echo -e "${GREEN}[6/6] Mise a jour .gitignore...${NC}"

GITIGNORE_ENTRIES=(
  "# MAOS Machine — locks (ne pas committer)"
  ".maos-pipeline/locks/*"
  "!.maos-pipeline/locks/.gitkeep"
)

if [ -f "$TARGET/.gitignore" ]; then
  for entry in "${GITIGNORE_ENTRIES[@]}"; do
    if ! grep -qF "$entry" "$TARGET/.gitignore" 2>/dev/null; then
      echo "$entry" >> "$TARGET/.gitignore"
    fi
  done
  echo -e "  ${GREEN}✓${NC} .gitignore mis a jour"
else
  printf '%s\n' "${GITIGNORE_ENTRIES[@]}" > "$TARGET/.gitignore"
  echo -e "  ${GREEN}✓${NC} .gitignore cree"
fi

# ============================================================
# Resume
# ============================================================
echo ""
echo -e "${PURPLE}══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  INSTALLATION TERMINEE !${NC}"
echo -e "${PURPLE}══════════════════════════════════════════════${NC}"
echo ""
echo -e "  Projet     : $TARGET"
echo -e "  Pipeline   : .maos-pipeline/ (10 dossiers)"
echo -e "  Agents     : .claude/commands/ (7 skills + auto-repair)"
echo -e "  MCP        : .mcp.json (11 servers)"
echo -e "  Permissions: .claude/settings.local.json"
echo ""
echo -e "${YELLOW}PROCHAINES ETAPES :${NC}"
echo ""
echo -e "  1. Editer ${BLUE}.mcp.json${NC} — remplacer les ___PLACEHOLDERS___"
echo -e "     - ___SENTRY_AUTH_TOKEN___"
echo -e "     - ___SENTRY_ORG___"
echo -e "     - ___PROJECT_PATH___"
echo -e "     - ___DATABASE_URL___"
echo -e "     - ___21ST_API_KEY___"
echo ""
echo -e "  2. Personnaliser ${BLUE}CLAUDE.md${NC} — stack, infra, regles metier"
echo ""
echo -e "  3. Lancer les agents dans des terminaux Claude Code :"
echo ""
echo -e "     ${GREEN}Terminal 1  :${NC} /loop 600 /stratege        ${YELLOW}# x1 ou plus${NC}"
echo -e "     ${GREEN}Terminal 2  :${NC} /loop 600 /code-dev        ${YELLOW}# x2, x3... pas de limite${NC}"
echo -e "     ${GREEN}Terminal 3  :${NC} /loop 600 /code-dev"
echo -e "     ${GREEN}Terminal 4  :${NC} /loop 600 /code-dev        ${YELLOW}# optionnel${NC}"
echo -e "     ${GREEN}Terminal 5  :${NC} /loop 600 /testeur         ${YELLOW}# x1 ou plus${NC}"
echo -e "     ${GREEN}Terminal 6  :${NC} /loop 600 /testeur         ${YELLOW}# optionnel${NC}"
echo -e "     ${GREEN}Terminal 7  :${NC} /loop 600 /devops          ${YELLOW}# x1${NC}"
echo -e "     ${GREEN}Terminal 8  :${NC} /loop 600 /designer        ${YELLOW}# x1 ou plus${NC}"
echo -e "     ${GREEN}Terminal 9  :${NC} /loop 600 /veilleur-tech   ${YELLOW}# x1 (ou cron 2 jours)${NC}"
echo ""
echo -e "  ${PURPLE}TOUS les agents supportent le mode parallele.${NC}"
echo -e "  ${PURPLE}Lock atomique mkdir — pas de collision, pas de limite.${NC}"
echo -e "  ${PURPLE}Le veilleur-tech auto-upgrade les MCP, skills, et modeles.${NC}"
echo ""
echo -e "${GREEN}La machine est prete. Lance les agents et laisse tourner.${NC}"
echo ""
