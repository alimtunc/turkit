---
name: handoff
description: Résume la conversation en cours pour l'envoyer à un autre LLM. Accepte un argument optionnel `ship` pour enchaîner le skill `ship` après le résumé. Usage - /handoff ou /handoff ship
---

# Handoff

Produis un résumé markdown de **cette conversation**, prêt à coller dans un autre LLM pour qu'il reprenne le fil.

## Argument

- **(aucun)** — comportement par défaut : commit + résumé.
- **`ship`** — après le résumé, enchaîner le skill `ship` (commit + push + PR + ticket Done). Dans ce mode, l'étape 1 ci-dessous est déléguée à `ship` (qui commit lui-même), donc le résumé est généré à partir du diff non commité avant d'invoquer `ship`.

## Étapes

1. **Commiter** tous les changements non commités avant de résumer. Suivre les règles de commit du projet (message concis, pas de `Co-Authored-By`). Si rien à commiter, passer à l'étape suivante.
   - **Mode `ship`** : sauter cette étape. `ship` commitera lui-même à la fin. Lire `git diff` et `git diff --cached` pour rédiger le résumé sur l'état non commité.
2. **Worktree → branche mère** — Si on est dans un git worktree :
   - Identifier la branche mère (celle depuis laquelle le worktree a été créé).
   - Pousser les commits du worktree vers la branche mère avec `git push origin HEAD:<branche-mère>` ou cherry-pick selon le cas.
   - Sortir du worktree (`ExitWorktree`) pour revenir à l'espace principal.
   - Supprimer le worktree (`git worktree remove <path>`).
   - Vérifier dans l'espace principal que les commits sont bien sur la branche mère (`git log --oneline -5`).
   - **Mode `ship`** : sauter cette étape. `ship` opère depuis la branche/worktree courant et publie la PR.
3. **Passer l'issue Linear en Done** — Si une issue Linear est associée à la conversation (identifiant DEV-XXXX dans les commits ou le contexte), la passer au statut "Done" via le MCP Linear (`save_issue` avec `stateId` correspondant à "Done").
   - **Mode `ship`** : sauter cette étape. `ship` ferme le ticket lui-même.
4. **Rédiger le résumé** — court et haut niveau. Objectif : l'autre LLM voit **où on en est** et **ce qu'on a fait**, pas le détail des fichiers. Couvrir :
   - Contexte (sur quoi on bossait, ticket associé)
   - Ce qu'on s'est dit d'important (décisions, arbitrages, pièges évités)
   - Ce qu'on a fait (résumé fonctionnel + résultat des gates : tests, lint, typecheck, vérif manuelle si applicable)
   - État de l'environnement (worktree conservé ou supprimé, branche poussée ou pas, statut Linear, PR ouverte / bundle / pas de PR)
   - Pointeur vers le(s) commit(s) — hash court + branche — en disant explicitement à l'autre LLM d'aller les lire (`git show <hash>`) pour être à jour sur le détail.
   - **Mode `ship`** : remplacer le pointeur de commit par un pointeur de **PR** (URL + numéro). `ship` fournira l'URL à l'étape 6.
5. **Afficher le résumé** dans un bloc markdown copiable (``` entouré).
6. **Mode `ship` uniquement** — invoquer le skill `ship` après avoir affiché le résumé. Si `ship` échoue (hook pre-commit, push refusé, etc.), surfacer l'erreur et **ne pas** considérer le handoff comme final tant que la PR n'est pas ouverte.

## Règles de rédaction

- **Ne pas lister les fichiers modifiés.** Si l'autre LLM a besoin du détail, il lit le commit.
- **Pas de section "Ce qui reste à faire".** Le handoff raconte l'état actuel, pas un backlog.
- **Toujours inclure l'état de l'environnement** : worktree (path / supprimé), branche (poussée ou pas), Linear (statut courant), PR (ouverte avec URL / bundlée / aucune). C'est ce qui dit à l'autre LLM où reprendre.
- **Toujours inclure le résultat des gates** dans "Ce qu'on a fait" : tests (n/n), lint, typecheck, et explicitement noter si la vérif manuelle UI n'a pas été faite.
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
- ...
- Gates : `<cmd tests>` X/X ✅ · `<cmd lint>` ✅ · `<cmd check>` ✅. **Vérif manuelle <surface> : faite / pas encore faite.**

## État de l'environnement
- Worktree `<path>` conservé / supprimé.
- Branche `<branche>` poussée sur origin / non poussée.
- Linear `<ID>` : **<statut>** (raison si pas Done).
- PR : `<url>` / bundlée avec `<autre PR>` / aucune.

## Pour être à jour
Lis le(s) commit(s) sur la branche `<branche>` :
- `<hash>` — <sujet du commit>

Fais `git show <hash>` pour voir le détail des changements.
```
````
