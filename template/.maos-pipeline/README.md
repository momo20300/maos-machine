# Pipeline Autonome — Agents IA Coordonnes

## Structure

```
.maos-pipeline/
├── PLAN.md        → direction du sprint (ecrit par le Chef)
├── ZONES.md       → carte des territoires (ecrit par le Chef)
├── STATUS.md      → etat temps reel de tous les agents (ecrit par le Chef)
├── backlog/       → taches creees par stratege, en attente de code-dev
├── in-progress/   → taches en cours d'execution par code-dev
├── review/        → taches terminees par code-dev, en attente du testeur
├── done/          → taches validees par testeur, pretes pour devops
├── blocked/       → taches bloquees (retour au stratege pour correction)
├── deployed/      → taches deployees en production
├── incidents/     → incidents prod detectes par devops
├── checkpoints/   → snapshots horaires du stratege + rapports veilleur-tech
├── locks/         → locks atomiques (ne pas modifier manuellement)
└── archived-v1/   → taches archivees
```

## Architecture

```
                    ┌─────────────────┐
                    │  CHEF D'ORCHESTRE│  ← cycle 180s, vision globale
                    │  PLAN + ZONES   │
                    │  + STATUS       │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
         PLAN.md        ZONES.md       STATUS.md
         (direction)    (territoires)  (temps reel)
              │              │              │
    ┌─────────┼─────────┐   │   ┌──────────┼──────────┐
    ▼         ▼         ▼   ▼   ▼          ▼          ▼
 STRATEGE  STRATEGE  DESIGNER  CODE-DEV  CODE-DEV  CODE-DEV
   x1+       x1+      x1+      x1+       x1+       x1+
    │                             │
    ▼                             ▼
 backlog/*.md              review/*.md
                                │
                    ┌───────────┼───────────┐
                    ▼                       ▼
                TESTEUR x1+           TESTEUR x1+
                    │                       │
               done/*.md              blocked/*.md
                    │                       │
                DEVOPS x1             STRATEGE
              (accord fondateur)     (correction)

         VEILLEUR-TECH x1
         (auto-upgrade MCP, skills, modeles tous les 2 jours)
```

## Lancement — Tous les agents sont parallelisables

```bash
# Minimal (8 terminaux)
Terminal 1  : /loop 180 /chef            # OBLIGATOIRE — cycle rapide 180s
Terminal 2  : /loop 900 /stratege
Terminal 3  : /loop 600 /code-dev        # instance 1
Terminal 4  : /loop 600 /code-dev        # instance 2
Terminal 5  : /loop 900 /testeur
Terminal 6  : /loop 900 /devops
Terminal 7  : /loop 900 /designer
Terminal 8  : /loop 600 /veilleur-tech   # ou cron tous les 2 jours

# Mode turbo (exemple 14 terminaux)
Terminal 1     : /loop 180 /chef          # x1 TOUJOURS (jamais plus)
Terminal 2-3   : /loop 900 /stratege      # x2
Terminal 4-8   : /loop 600 /code-dev      # x5
Terminal 9-10  : /loop 900 /testeur       # x2
Terminal 11    : /loop 900 /devops        # x1
Terminal 12-13 : /loop 900 /designer      # x2
Terminal 14    : /loop 600 /veilleur-tech # x1
```

**Le Chef d'Orchestre est TOUJOURS lance en premier. Jamais plus d'1 instance.**
Tous les autres agents utilisent un **lock atomique mkdir** — pas de limite d'instances.

## Regles

1. Autonomie totale — aucun agent ne demande l'avis du fondateur sauf pour git push/deploy
2. Communication par fichiers — chaque tache est un fichier MD numerote
3. Deux rapports obligatoires — code-dev ET testeur avant decision du stratege
4. Blocage = retour au stratege
5. Deploy = accord fondateur
6. Backlog vide = stratege audite le code et cree de nouvelles taches
7. Incidents = priorite absolue
