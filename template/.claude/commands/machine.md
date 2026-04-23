# /machine — Initialiser et lancer la pipeline autonome multi-agents

Tu es l'installateur de la MAOS Machine. Quand l'utilisateur tape `/machine`, tu fais TOUT automatiquement.

---

## FLOW COMPLET

### Etape 1 — Detecter le contexte

```bash
echo "=== DETECTION ===" && \
echo "Dossier: $(pwd)" && \
echo "Fichiers: $(ls -1 | wc -l)" && \
echo "Git: $(git rev-parse --is-inside-work-tree 2>/dev/null || echo 'non')" && \
echo "CLAUDE.md: $([ -f CLAUDE.md ] && echo 'existe' || echo 'absent')" && \
echo "Pipeline: $([ -d .maos-pipeline ] && echo 'existe' || echo 'absent')" && \
echo "package.json: $([ -f package.json ] && echo 'existe' || echo 'absent')"
```

### Etape 2 — Poser les questions (via conversation, PAS un script bash)

Demande a l'utilisateur EN FRANCAIS dans la conversation :

1. **"Combien d'agents de chaque type ?"**
   Propose le defaut et laisse modifier :
   ```
   Chef d'orchestre : 1 (toujours 1)
   Stratege         : 1
   Code-dev         : 2
   Testeur          : 1
   DevOps           : 1
   Designer         : 1
   Veilleur-tech    : 1
   ──────────────────
   Total            : 8 terminaux

   Modifie les nombres si tu veux, ou Entree pour valider.
   ```

2. **"APIs disponibles ?"** (chaque reponse est optionnelle)
   ```
   Sentry token     : (colle ou skip)
   Sentry org       : (si token fourni)
   Database URL     : (postgresql://... ou skip)
   21st.dev API key : (colle ou skip)
   ```

3. **Si CLAUDE.md n'existe PAS et le dossier est vide/nouveau :**
   ```
   "Decris ta vision du projet en quelques lignes :"
   ```
   L'utilisateur decrit son idee. Tu l'utiliseras pour le CLAUDE.md.

4. **Si le dossier contient deja du code (projet existant) :**
   ```
   "Je detecte un projet existant. Je vais scanner le code et installer la pipeline par-dessus."
   ```
   Pas besoin de vision — le stratege auditera le code.

### Etape 3 — Installer (silencieux et rapide)

```bash
# 1. Cloner le template si pas deja present
if [ ! -d /tmp/maos-machine ]; then
  git clone https://github.com/momo20300/maos-machine.git /tmp/maos-machine 2>/dev/null
else
  cd /tmp/maos-machine && git pull origin master 2>/dev/null
  cd -
fi
```

Ensuite executer les installations :

**Pipeline :**
```bash
DIRS=("backlog" "in-progress" "review" "done" "blocked" "deployed" "incidents" "checkpoints" "locks" "archived-v1")
for dir in "${DIRS[@]}"; do
  mkdir -p ".maos-pipeline/$dir"
  touch ".maos-pipeline/$dir/.gitkeep"
done
cp /tmp/maos-machine/template/.maos-pipeline/README.md .maos-pipeline/README.md
```

**Agents :**
```bash
mkdir -p .claude/commands
for agent in chef stratege code-dev testeur devops designer veilleur-tech auto-repair; do
  cp "/tmp/maos-machine/template/.claude/commands/${agent}.md" ".claude/commands/${agent}.md"
done
```

**Settings :**
```bash
[ -f .claude/settings.local.json ] && cp .claude/settings.local.json .claude/settings.local.json.bak
cp /tmp/maos-machine/template/.claude/settings.local.json .claude/settings.local.json
```

**MCP (.mcp.json) :**
Generer le fichier avec les VRAIES valeurs fournies par l'utilisateur (pas de placeholders). 
- Toujours inclure : fetch, filesystem, chrome-devtools, magic-ui, ui-ux-pro, shadcn-ui, playwright, memory
- Ajouter sentry SI token fourni
- Ajouter postgres SI URL fournie
- Ajouter 21st-magic SI key fournie
- Le chemin filesystem = le dossier actuel (pwd), converti en format Windows

**CLAUDE.md** (si absent) :
Generer avec la vision du fondateur, la date, le nom du projet (basename du dossier), la stack detectee.
Ajouter section "VISION DU FONDATEUR" avec le texte de l'utilisateur.
Ajouter section "PIPELINE AUTONOME" qui decrit les agents.

**Premiere tache** (si backlog vide) :
Creer `.maos-pipeline/backlog/001_initialisation-projet.md` avec :
- Instructions pour le stratege de lire CLAUDE.md et decomposer la vision en taches
- La vision du fondateur copiee dans la tache

**.gitignore** :
Ajouter `.maos-pipeline/locks/*` si pas deja present.

**git init** si pas deja un repo git.

### Etape 4 — Lancer les terminaux AUTOMATIQUEMENT

Utilise la commande `start` Windows pour ouvrir chaque terminal :

```bash
PROJECT_PATH=$(pwd)
# Convertir en chemin Windows
PROJECT_PATH_WIN=$(echo "$PROJECT_PATH" | sed 's|/c/|C:/|' | sed 's|/|\\|g')

# Chef en premier (toujours)
start "CHEF" cmd /k "cd /d \"$PROJECT_PATH_WIN\" && claude -p \"/loop 120 /chef\""
sleep 3

# Stratege
start "STRATEGE" cmd /k "cd /d \"$PROJECT_PATH_WIN\" && claude -p \"/loop 600 /stratege\""
sleep 2

# Code-dev (autant que demande)
# Pour chaque instance :
start "CODE-DEV-1" cmd /k "cd /d \"$PROJECT_PATH_WIN\" && claude -p \"/loop 600 /code-dev\""
sleep 2
start "CODE-DEV-2" cmd /k "cd /d \"$PROJECT_PATH_WIN\" && claude -p \"/loop 600 /code-dev\""
sleep 2

# Testeur
start "TESTEUR" cmd /k "cd /d \"$PROJECT_PATH_WIN\" && claude -p \"/loop 600 /testeur\""
sleep 2

# DevOps
start "DEVOPS" cmd /k "cd /d \"$PROJECT_PATH_WIN\" && claude -p \"/loop 600 /devops\""
sleep 2

# Designer
start "DESIGNER" cmd /k "cd /d \"$PROJECT_PATH_WIN\" && claude -p \"/loop 600 /designer\""
sleep 2

# Veilleur-tech
start "VEILLEUR-TECH" cmd /k "cd /d \"$PROJECT_PATH_WIN\" && claude -p \"/loop 600 /veilleur-tech\""
```

### Etape 5 — Confirmer

Affiche le resume :

```
═══════════════════════════════════════════════════
  MAOS MACHINE — DEMARREE
═══════════════════════════════════════════════════

  Projet  : [nom]
  Dossier : [chemin]
  Type    : [nouveau / existant]

  Agents lances :
    Chef           x1  (cycle 120s)
    Stratege       x[N] (cycle 600s)
    Code-dev       x[N] (cycle 600s)
    Testeur        x[N] (cycle 600s)
    DevOps         x1  (cycle 600s)
    Designer       x[N] (cycle 600s)
    Veilleur-tech  x1  (cycle 600s)
    ─────────────────
    Total          [N] terminaux

  MCP actifs : [liste]

  La machine tourne. Les agents enrichissent ta vision.
  Verifie les checkpoints/ pour suivre l'avancement.

  Pour arreter : ferme les fenetres ou tape "stop" dans chaque terminal.
═══════════════════════════════════════════════════
```

---

## REGLES

1. **Tout est automatique** — ne jamais dire "edite tel fichier" ou "configure manuellement"
2. **Questions en francais** — claires, courtes, avec defaut entre parentheses
3. **Skip = c'est OK** — chaque API est optionnelle sauf la vision (si dossier vide)
4. **Projet existant = pas de vision** — le stratege auditera le code
5. **Chef toujours x1** — ne pas laisser l'utilisateur mettre plus de 1
6. **Ouvrir les terminaux** — utiliser `start` Windows, pas juste afficher les commandes
7. **Feedback visuel** — montrer la progression pendant l'installation
