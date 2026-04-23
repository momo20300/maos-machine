# Auto-Repair — Regles communes a tous les agents

## Si un outil MCP echoue

Quand tu appelles un MCP et que tu recois une erreur du type :
- "MCP server XXX failed to start"
- "tool not found"
- "command not found"
- "npx: command XXX not found"

### Procedure de reparation automatique

```bash
# 1. Identifier le package depuis .mcp.json
cat .mcp.json | grep -A5 "NOM_DU_MCP"

# 2. Tenter la reinstallation
npx -y PACKAGE_NAME@latest --version 2>/dev/null

# 3. Si echec — le package a peut-etre change de nom
# Chercher le remplacement
# WebSearch "PACKAGE_NAME npm mcp alternative"

# 4. Si un remplacement est trouve :
#    a. Backup .mcp.json
cp .mcp.json .mcp.json.bak
#    b. Modifier .mcp.json avec le nouveau package
#    c. Tester
npx -y NOUVEAU_PACKAGE@latest --version 2>/dev/null
#    d. Documenter dans checkpoints/

# 5. Si rien ne marche → creer un incident
# Ecrire dans .maos-pipeline/incidents/TOOL_BROKEN_NOM.md
```

### Ne JAMAIS ignorer un outil casse

Un outil casse = capacite perdue. Tu dois :
1. **Tenter la reparation** (3 essais max)
2. **Si repare** → continuer ton travail normalement
3. **Si pas repare** → creer un incident pour le veilleur-tech ou le stratege
4. **Continuer ton travail** sans l'outil casse (mode degrade)

## Si un package npm manque dans le projet

```bash
# Verifier si le package est dans package.json
grep "PACKAGE_NAME" package.json

# Si absent mais necessaire
npm install PACKAGE_NAME
# ou
npm install --save-dev PACKAGE_NAME

# Rebuild apres installation
npm run build
```

## Si une commande CLI manque

```bash
# Tenter installation globale
npm install -g COMMANDE 2>/dev/null || npx -y COMMANDE --version

# Si c'est un outil systeme (pas npm)
# → Creer un incident, ne pas tenter d'installer des packages systeme
```

## Mise a jour automatique des modeles

A chaque lancement, verifie le model ID dans ta config :
- Si CLAUDE.md specifie un model ID
- Si ton model actuel est different
- Si le model specifie est disponible

**Regle** : toujours utiliser le modele le plus puissant disponible pour les taches critiques (DB, auth, securite, architecture). Sonnet acceptable pour les petites corrections. Haiku jamais sauf si explicitement autorise.

Si tu detectes qu'un nouveau modele est disponible et que tu ne l'utilises pas, note-le dans ton rapport pour le veilleur-tech.
