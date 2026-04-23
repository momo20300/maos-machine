#!/bin/bash
# ============================================================
# MAOS Machine — Installation one-shot
# ============================================================
# Colle cette ligne n'importe ou et c'est fait :
#
#   bash <(curl -s https://raw.githubusercontent.com/momo20300/maos-machine/master/install.sh)
#
# Ou si deja clone :
#
#   bash install.sh
#
# Ca installe /machine globalement. Ensuite tape /machine
# dans n'importe quel projet Claude Code.
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo ""
echo -e "${PURPLE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   MAOS Machine — Installation rapide        ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Cloner le repo si pas deja present
MACHINE_DIR="/tmp/maos-machine"
if [ ! -d "$MACHINE_DIR" ]; then
  echo -e "${GREEN}Telechargement de maos-machine...${NC}"
  git clone https://github.com/momo20300/maos-machine.git "$MACHINE_DIR" 2>/dev/null
else
  echo -e "${GREEN}Mise a jour de maos-machine...${NC}"
  cd "$MACHINE_DIR" && git pull origin master 2>/dev/null && cd - >/dev/null
fi

# Installer /machine globalement
echo -e "${GREEN}Installation de /machine...${NC}"
mkdir -p "$HOME/.claude/commands"
cp "$MACHINE_DIR/template/.claude/commands/machine.md" "$HOME/.claude/commands/machine.md"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  INSTALLE !${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "  La commande ${PURPLE}/machine${NC} est maintenant disponible."
echo ""
echo -e "  Pour l'utiliser :"
echo -e "  1. Ouvre Claude Code dans n'importe quel dossier"
echo -e "  2. Tape : ${PURPLE}/machine${NC}"
echo -e "  3. C'est tout."
echo ""
