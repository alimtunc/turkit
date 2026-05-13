---
name: handoff
description: Résume la conversation en cours pour l'envoyer à un autre LLM. Usage - /handoff
---

# Handoff

Produis un résumé markdown de **cette conversation**, prêt à coller dans un autre LLM pour qu'il reprenne le fil.

## Étapes

1. **Commiter** tous les changements non commités avant de résumer. Suivre les règles de commit du projet (message concis, pas de `Co-Authored-By`). Si rien à commiter, passer à l'étape suivante.
2. **Worktree → branche mère** — Si on est dans un git worktree :
   - Identifier la branche mère (celle depuis laquelle le worktree a été créé).
   - Pousser les commits du worktree vers la branche mère avec `git push origin HEAD:<branche-mère>` ou cherry-pick selon le cas.
   - Sortir du worktree (`ExitWorktree`) pour revenir à l'espace principal.
   - Supprimer le worktree (`git worktree remove <path>`).
   - Vérifier dans l'espace principal que les commits sont bien sur la branche mère (`git log --oneline -5`).
3. **Passer l'issue Linear en Done** — Si une issue Linear est associée à la conversation (identifiant DEV-XXXX dans les commits ou le contexte), la passer au statut "Done" via le MCP Linear (`save_issue` avec `stateId` correspondant à "Done").
4. **Rédiger le résumé** — court et haut niveau. Objectif : l'autre LLM voit **où on en est** et **ce qu'on a fait**, pas le détail des fichiers. Couvrir :
   - Contexte (sur quoi on bossait, ticket associé)
   - Ce qu'on s'est dit d'important (décisions, arbitrages, pièges évités)
   - Ce qu'on a fait (résumé fonctionnel, pas la liste des fichiers)
   - Pointeur vers le(s) commit(s) — hash court + branche — en disant explicitement à l'autre LLM d'aller les lire (`git show <hash>`) pour être à jour sur le détail.
5. **Afficher le résumé** dans un bloc markdown copiable (``` entouré).

## Règles de rédaction

- **Ne pas lister les fichiers modifiés.** Si l'autre LLM a besoin du détail, il lit le commit.
- **Pas de section "Ce qui reste à faire".** Le handoff raconte l'état actuel, pas un backlog.
- Rester factuel et dense : pas de remplissage, pas de reformulation du ticket.

## Format de sortie

Toujours afficher le résumé dans un **bloc de code markdown** pour que l'utilisateur puisse le copier/coller en un clic. Exemple :

````
```markdown
# Handoff — [titre du ticket ou sujet]

## Contexte
...

## Décisions / points importants
...

## Ce qu'on a fait
...

## Pour être à jour
Lis le(s) commit(s) sur la branche `<branche>` :
- `<hash>` — <sujet du commit>

Fais `git show <hash>` pour voir le détail des changements.
```
````
