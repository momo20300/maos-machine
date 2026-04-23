# Pipeline Autonome — 6 Agents IA

## Structure

```
.maos-pipeline/
├── backlog/       → taches creees par stratege, en attente de code-dev
├── in-progress/   → taches en cours d'execution par code-dev
├── review/        → taches terminees par code-dev, en attente du testeur
├── done/          → taches validees par testeur, pretes pour devops
├── blocked/       → taches bloquees (retour au stratege pour correction)
├── deployed/      → taches deployees en production
├── incidents/     → incidents prod detectes par devops
├── checkpoints/   → snapshots horaires du stratege
├── locks/         → locks pour code-dev parallele (ne pas modifier manuellement)
└── archived-v1/   → taches archivees
```

## Flux de travail

```
STRATEGE (analyse, planifie)
     │
     ▼
backlog/*.md ──→ CODE-DEV x2 (code, build) ──→ review/*.md ──→ TESTEUR (audit, test)
                                                                     │
                                                           ┌────────┴────────┐
                                                           │                 │
                                                       done/*.md        blocked/*.md
                                                           │                 │
                                                       DEVOPS           STRATEGE
                                                   (deploy avec        (analyse +
                                                    accord fondateur)   correction)

DESIGNER (independant) ──→ DESIGN-NNN.md dans backlog/ ──→ code-dev implemente
```

## Lancement — Tous les agents sont parallelisables

```bash
# Minimum (7 terminaux)
Terminal 1  : /loop 600 /stratege
Terminal 2  : /loop 600 /code-dev        # instance 1
Terminal 3  : /loop 600 /code-dev        # instance 2
Terminal 4  : /loop 600 /testeur
Terminal 5  : /loop 600 /devops
Terminal 6  : /loop 600 /designer
Terminal 7  : /loop 600 /veilleur-tech   # ou cron tous les 2 jours

# Mode turbo (exemple 12 terminaux)
Terminal 1-2   : /loop 600 /stratege     # x2
Terminal 3-6   : /loop 600 /code-dev     # x4
Terminal 7-8   : /loop 600 /testeur      # x2
Terminal 9     : /loop 600 /devops       # x1
Terminal 10-11 : /loop 600 /designer     # x2
Terminal 12    : /loop 600 /veilleur-tech # x1
```

Chaque agent utilise un **lock atomique mkdir** — pas de collision, pas de limite d'instances.

## Regles

1. Autonomie totale — aucun agent ne demande l'avis du fondateur sauf pour git push/deploy
2. Communication par fichiers — chaque tache est un fichier MD numerote
3. Deux rapports obligatoires — code-dev ET testeur avant decision du stratege
4. Blocage = retour au stratege
5. Deploy = accord fondateur
6. Backlog vide = stratege audite le code et cree de nouvelles taches
7. Incidents = priorite absolue
