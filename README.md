# MAOS Machine — Pipeline Autonome IA

> Ouvre Claude Code → tape `/machine` → la machine construit ton projet pendant que tu dors.

## Qu'est-ce que c'est ?

Une machine de développement autonome basée sur **Claude Code**. 8 agents IA tournent en boucle et construisent/améliorent ton projet automatiquement.

- **Dossier vide** → les agents construisent ton idée
- **Projet existant** → les agents auditent et améliorent

Aucun code n'est partagé. Seuls les agents et la config sont dans ce repo. Ton code reste dans TON projet.

## Prérequis

- [Claude Code CLI](https://claude.ai/code)
- Node.js >= 18
- Git
- Compte GitHub
- Windows 10/11

## Utilisation rapide

### Méthode 1 — `/machine` (recommandé)

1. Copie `template/.claude/commands/machine.md` dans `~/.claude/commands/machine.md`
2. Ouvre Claude Code dans n'importe quel dossier
3. Tape : `/machine`
4. Réponds aux questions (agents, APIs, vision)
5. La machine s'installe et démarre toute seule

### Méthode 2 — init.sh

```bash
git clone https://github.com/momo20300/maos-machine.git
bash maos-machine/init.sh /chemin/vers/ton/projet
# Puis double-clic sur start-machine.bat
```

## Les 8 agents

| Agent | Instances | Cycle | Rôle |
|---|---|---|---|
| **Chef d'orchestre** | x1 | 120s | Coordonne, empêche les conflits |
| **Stratège** | x1+ | 600s | Planifie, crée les tâches |
| **Code-dev** | x2+ | 600s | Code dans sa zone assignée |
| **Testeur** | x1+ | 600s | Audite, screenshots, valide |
| **DevOps** | x1 | 600s | Monitoring, deploy |
| **Designer** | x1+ | 600s | Specs UI/UX avec MCP |
| **Veilleur-tech** | x1 | 2 jours | Auto-upgrade MCP/modèles |
| **Auto-repair** | partagé | - | Répare les outils cassés |

Tous les agents sauf le Chef sont parallélisables. Lock atomique `mkdir` — pas de collision, pas de limite.

## Convention de nommage

| Situation | Suffixe | Exemple |
|---|---|---|
| Projet créé from scratch | `-cpromax` | `mon-app-cpromax` |
| Projet existant amélioré | `-promax` | `mon-app-promax` |

L'original n'est **jamais** modifié. En mode amélioration, le projet est copié.

## Ce que la machine installe

```
.maos-pipeline/
├── PLAN.md         → Direction du sprint (par le Chef)
├── ZONES.md        → Carte des territoires (par le Chef)
├── STATUS.md       → État temps réel (par le Chef)
├── backlog/        → Tâches en attente
├── in-progress/    → Tâches en cours
├── review/         → En attente d'audit
├── done/           → Validées
├── blocked/        → Bloquées
├── deployed/       → En production
├── incidents/      → Problèmes prod
├── checkpoints/    → Rapports périodiques
└── locks/          → Locks atomiques

.claude/commands/   → 8 agents + auto-repair
.mcp.json           → Jusqu'à 11 MCP servers
CLAUDE.md           → Vision + règles + état
start-machine.bat   → Double-clic = démarrer
stop-machine.bat    → Double-clic = arrêter
```

## MCP Servers inclus

**Toujours actifs :** fetch, filesystem, chrome-devtools, magic-ui, shadcn-ui, ui-ux-pro, playwright, memory

**Optionnels :** sentry, postgres, 21st-magic

## Comportements automatiques

- **Auto-install** — Si un outil manque, l'agent l'installe
- **Auto-upgrade** — Le veilleur checke les nouveautés tous les 2 jours
- **Auto-model** — Si un modèle plus puissant sort, la machine switche
- **Auto-repair** — Si un MCP crashe, réparation automatique
- **Auto-scaling** — Le chef recommande d'ajouter/retirer des agents

## Protection

- **Ce repo est sacré** — Aucun agent ne le modifie. C'est le moule, les projets sont les pièces.
- **L'original intact** — En mode amélioration, le projet est copié, jamais modifié.
- **Deploy = accord fondateur** — Le DevOps ne push jamais en prod sans validation.

## Licence

Propriétaire — MAOS Software Ltd (Ireland)

---

*by mOOn — Marrakech*
