# /machine — Initialiser et lancer la pipeline autonome multi-agents

Tu es l'installateur de la MAOS Machine. Quand l'utilisateur tape `/machine`, tu fais TOUT automatiquement.

---

## FLOW COMPLET

### Etape 1 — Detecter le contexte

```bash
echo "=== DETECTION ===" && \
echo "Dossier: $(pwd)" && \
NFILES=$(ls -1A 2>/dev/null | grep -v "^\.git$" | wc -l) && \
echo "Fichiers: $NFILES" && \
echo "Git: $(git rev-parse --is-inside-work-tree 2>/dev/null || echo 'non')" && \
echo "CLAUDE.md: $([ -f CLAUDE.md ] && echo 'existe' || echo 'absent')" && \
echo "Pipeline: $([ -d .maos-pipeline ] && echo 'existe' || echo 'absent')" && \
echo "package.json: $([ -f package.json ] && echo 'existe' || echo 'absent')"
```

Determine le MODE :
- **$NFILES = 0** (ou seulement .git) → **MODE CREATION** (dossier vide, nouveau projet)
- **$NFILES > 0** → **MODE AMELIORATION** (projet existant)

### Etape 1b — Convention de nommage Git

**MODE CREATION (dossier vide)** :
- Nom du repo = `NOM-cpromax` (c = creation, promax = pipeline max)
- Creer un NOUVEAU repo git avec ce nom
- Creer le repo sur GitHub automatiquement :
  ```bash
  BASENAME=$(basename "$(pwd)")
  # Retirer -cpromax si deja present pour eviter doublon
  CLEAN_NAME=$(echo "$BASENAME" | sed 's/-cpromax$//' | sed 's/-promax$//')
  REPO_NAME="${CLEAN_NAME}-cpromax"

  git init
  git checkout -b main

  # Creer sur GitHub
  curl -s -X POST https://api.github.com/user/repos \
    -H "Authorization: token $(git credential-manager get <<< $'protocol=https\nhost=github.com' 2>/dev/null | grep password | cut -d= -f2)" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "{\"name\":\"$REPO_NAME\",\"private\":false,\"description\":\"Projet cree par MAOS Machine\"}"

  git remote add origin "https://github.com/$(git config user.name || echo momo20300)/$REPO_NAME.git"
  ```

**MODE AMELIORATION (projet existant)** :
- Sauvegarder le remote original :
  ```bash
  ORIGINAL_REMOTE=$(git remote get-url origin 2>/dev/null || echo "none")
  BASENAME=$(basename "$(pwd)")
  CLEAN_NAME=$(echo "$BASENAME" | sed 's/-cpromax$//' | sed 's/-promax$//')
  REPO_NAME="${CLEAN_NAME}-promax"
  ```
- Creer une copie du projet dans un NOUVEAU dossier a cote :
  ```bash
  PARENT=$(dirname "$(pwd)")
  NEW_DIR="$PARENT/$REPO_NAME"

  # Copier tout le projet (sauf .git)
  mkdir -p "$NEW_DIR"
  rsync -a --exclude='.git' "$(pwd)/" "$NEW_DIR/"
  # Ou si pas rsync :
  # cp -r . "$NEW_DIR/" && rm -rf "$NEW_DIR/.git"

  cd "$NEW_DIR"
  git init
  git checkout -b main
  ```
- Creer le repo GitHub :
  ```bash
  curl -s -X POST https://api.github.com/user/repos \
    -H "Authorization: token $(git credential-manager get <<< $'protocol=https\nhost=github.com' 2>/dev/null | grep password | cut -d= -f2)" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "{\"name\":\"$REPO_NAME\",\"private\":false,\"description\":\"Version PROMAX de $CLEAN_NAME — ameliore par MAOS Machine. Original: $ORIGINAL_REMOTE\"}"

  git remote add origin "https://github.com/$(git config user.name || echo momo20300)/$REPO_NAME.git"
  ```
- Ajouter dans CLAUDE.md :
  ```
  ## ORIGINE
  Ce projet est une version PROMAX de : $ORIGINAL_REMOTE
  Dossier original : $PARENT/$CLEAN_NAME
  Pour comparer : diff entre les deux dossiers ou repos
  ```

**Resultat** :
- `mon-app/` → original intact, inchange
- `mon-app-promax/` → copie avec pipeline + agents + ameliorations
- OU `mon-idee-cpromax/` → creation from scratch avec pipeline

### Etape 2 — Poser les questions (via conversation, PAS un script bash)

Demande a l'utilisateur EN FRANCAIS dans la conversation :

1. **"Combien d'agents de chaque type ?"**
   Propose le defaut et laisse modifier :
   ```
   Chef d'orchestre : 1 (toujours 1, non modifiable)
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

3. **MODE CREATION uniquement :**
   ```
   "Decris ta vision du projet :"
   ```
   L'utilisateur decrit son idee. Tu l'utiliseras pour le CLAUDE.md.

4. **MODE AMELIORATION :**
   ```
   "Projet existant detecte. Je copie dans NOM-promax/ et j'installe la pipeline.
    L'original reste intact. Les agents vont auditer et ameliorer."
   ```

### Etape 3 — Installer (silencieux et rapide)

**Le dossier de travail est maintenant le bon** (soit le dossier vide, soit le nouveau `-promax`).

```bash
# 1. Cloner le template si pas deja present
if [ ! -d /tmp/maos-machine ]; then
  git clone https://github.com/momo20300/maos-machine.git /tmp/maos-machine 2>/dev/null
else
  cd /tmp/maos-machine && git pull origin master 2>/dev/null && cd -
fi
```

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

**CLAUDE.md :**
- MODE CREATION : generer avec vision du fondateur + pipeline + date + nom
- MODE AMELIORATION : ajouter les sections pipeline et origine au CLAUDE.md existant (ou le creer s'il n'existe pas)

**Premiere tache** (si backlog vide) :
Creer `.maos-pipeline/backlog/001_initialisation-projet.md` :
- MODE CREATION : instructions pour decomposer la vision en taches
- MODE AMELIORATION : instructions pour auditer le code existant et creer un plan d'amelioration

**.gitignore** :
Ajouter `.maos-pipeline/locks/*` si pas deja present.

**Premier commit :**
```bash
git add -A
git commit -m "feat: initialisation MAOS Machine pipeline autonome

- 8 agents (chef, stratege, code-dev, testeur, devops, designer, veilleur-tech, auto-repair)
- Pipeline .maos-pipeline/ (10 dossiers)
- MCP configures
- Premiere tache backlog/001

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

git push -u origin main 2>/dev/null || true
```

### Etape 4 — Generer start-machine.bat et stop-machine.bat

Creer les scripts BAT dans le dossier du projet (meme logique que init.sh mais adapte au nombre d'agents choisi par l'utilisateur).

### Etape 5 — Lancer les terminaux AUTOMATIQUEMENT

```bash
PROJECT_PATH=$(pwd)
PROJECT_PATH_WIN=$(echo "$PROJECT_PATH" | sed 's|/c/|C:/|' | sed 's|/|\\|g')

# Chef en premier (toujours x1)
start "CHEF" cmd /k "cd /d \"$PROJECT_PATH_WIN\" && claude -p \"/loop 450 /chef\""
sleep 3

# Stratege (x nombre choisi)
start "STRATEGE" cmd /k "cd /d \"$PROJECT_PATH_WIN\" && claude -p \"/loop 900 /stratege\""
sleep 2

# Code-dev (x nombre choisi)
# Boucle pour chaque instance demandee
start "CODE-DEV-1" cmd /k "cd /d \"$PROJECT_PATH_WIN\" && claude -p \"/loop 600 /code-dev\""
sleep 2
start "CODE-DEV-2" cmd /k "cd /d \"$PROJECT_PATH_WIN\" && claude -p \"/loop 600 /code-dev\""
sleep 2

# Testeur (x nombre choisi)
start "TESTEUR" cmd /k "cd /d \"$PROJECT_PATH_WIN\" && claude -p \"/loop 900 /testeur\""
sleep 2

# DevOps (x1)
start "DEVOPS" cmd /k "cd /d \"$PROJECT_PATH_WIN\" && claude -p \"/loop 900 /devops\""
sleep 2

# Designer (x nombre choisi)
start "DESIGNER" cmd /k "cd /d \"$PROJECT_PATH_WIN\" && claude -p \"/loop 900 /designer\""
sleep 2

# Veilleur-tech (x1 — premier scan puis hebdomadaire)
start "VEILLEUR-TECH" cmd /k "cd /d \"$PROJECT_PATH_WIN\" && claude -p \"/veilleur-tech\""
```

### Etape 6 — Confirmer

```
═══════════════════════════════════════════════════
  MAOS MACHINE — DEMARREE
═══════════════════════════════════════════════════

  Mode    : CREATION (-cpromax) / AMELIORATION (-promax)
  Projet  : [nom-cpromax ou nom-promax]
  Dossier : [chemin]
  GitHub  : https://github.com/USER/REPO

  Original (si amelioration) :
    Dossier : [chemin original — intact]
    Repo    : [remote original]

  Agents lances :
    Chef           x1  (cycle 450s — Sonnet)
    Stratege       x[N] (cycle 900s — Opus)
    Code-dev       x[N] (cycle 600s — Opus)
    Testeur        x[N] (cycle 900s — Sonnet)
    DevOps         x1  (cycle 900s — Sonnet)
    Designer       x[N] (cycle 900s — Sonnet)
    Veilleur-tech  x1  (hebdomadaire — Sonnet)
    ─────────────────
    Total          [N] terminaux

  MCP actifs : [liste]

  Pour arreter : ferme les fenetres ou double-clic stop-machine.bat
═══════════════════════════════════════════════════
```

---

## REGLES

1. **Tout est automatique** — ne jamais dire "edite tel fichier" ou "configure manuellement"
2. **Questions en francais** — claires, courtes, avec defaut entre parentheses
3. **Skip = OK** — chaque API est optionnelle
4. **Chef toujours x1** — non modifiable
5. **Ouvrir les terminaux** — utiliser `start` Windows, pas juste afficher les commandes
6. **Convention de nommage** :
   - Dossier vide → `nom-cpromax` (creation from scratch)
   - Projet existant → `nom-promax` (amelioration, original intact)
7. **Git repo sur GitHub** — creer automatiquement avec le bon nom
8. **Original JAMAIS modifie** — en mode amelioration, toujours copier d'abord
9. **Premier commit automatique** — tout installer, committer, pusher
10. **start-machine.bat + stop-machine.bat** — generes dans le projet

## REGLE INVIOLABLE — PROTECTION DU REPO maos-machine

**Le repo `maos-machine` (github.com/momo20300/maos-machine) est SACRE.**

- AUCUN agent ne modifie les fichiers dans `/tmp/maos-machine/` ou dans le repo source
- AUCUN agent ne push vers `maos-machine`
- AUCUN agent ne cree de branche sur `maos-machine`
- Les templates sont COPIES depuis maos-machine vers le projet cible — jamais l'inverse
- Si un agent detecte un bug dans un template → il cree une tache dans SON projet, pas dans maos-machine
- Seul mOOn (le fondateur) decide de modifier maos-machine, manuellement, en dehors de la pipeline

**maos-machine est le moule. Les projets sont les pieces. On ne modifie jamais le moule depuis les pieces.**
