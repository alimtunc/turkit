---
name: handoff
description: Résume la conversation en cours pour l'envoyer à un autre LLM. Accepte un argument optionnel `ship` pour enchaîner le skill `ship` après le résumé. Usage - /handoff ou /handoff ship
---

# Handoff

Produis un résumé markdown de **cette conversation**, prêt à coller dans un autre LLM pour qu'il reprenne le fil.

## Argument

- **(aucun)** — commit + résumé.
- **`ship`** — déléguer commit + push + PR + ticket Done au skill `ship`, puis afficher le résumé avec l'URL de la PR.

## Étapes (mode défaut)

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
   - Ce qu'on a fait (résumé fonctionnel + résultat des gates : tests, lint, typecheck, vérif manuelle si applicable)
   - État de l'environnement (worktree conservé ou supprimé, branche poussée ou pas, statut Linear, PR ouverte / bundle / pas de PR)
   - Pointeur vers le(s) commit(s) — hash court + branche — en disant explicitement à l'autre LLM d'aller les lire (`git show <hash>`) pour être à jour sur le détail.
5. **Afficher le résumé** dans un bloc markdown copiable (``` entouré).

## Étapes (mode `ship`)

1. **Préparer le brouillon** du résumé à partir de `git diff` et `git diff --cached` (le commit n'existe pas encore).
2. **Invoquer le skill `ship`** (commit + push + PR + ticket Done). Si `ship` échoue (hook pre-commit, push refusé, etc.), surfacer l'erreur telle quelle et **ne pas** afficher de résumé.
3. **Capturer l'URL et le numéro de PR** depuis la sortie de `ship` (dernière ligne `#<PR_NUMBER>`, ligne `PR : <url>`).
4. **Afficher le résumé** avec le pointeur de PR (URL + numéro) à la place du pointeur de commit, dans le bloc markdown copiable.
5. **Réémettre le bloc final de `ship`** juste après la fence de fermeture du résumé. Le bare `#<PR_NUMBER>` reste la toute dernière ligne de la réponse.

## Règles de rédaction

- **Ne pas lister les fichiers modifiés.** Si l'autre LLM a besoin du détail, il lit le commit.
- **Pas de section "Ce qui reste à faire".** Le handoff raconte l'état actuel, pas un backlog.
- **Toujours inclure l'état de l'environnement** : worktree (path / supprimé), branche (poussée ou pas), Linear (statut courant), PR (ouverte avec URL / bundlée / aucune). C'est ce qui dit à l'autre LLM où reprendre.
- **Toujours inclure le résultat des gates** dans "Ce qu'on a fait" : tests (n/n), lint, typecheck, et explicitement noter si la vérif manuelle UI n'a pas été faite.
- Rester factuel et dense : pas de remplissage, pas de reformulation du ticket.

## Format de sortie

Toujours afficher le résumé dans un **bloc de code markdown** pour que l'utilisateur puisse le copier/coller en un clic. Pas de phrase d'intro avant la fence, rien après la fence de fermeture (sauf en mode `ship`, où le trailer de `ship` suit). Exemple :

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

### Variante mode `ship`

Même gabarit, avec deux ajustements :

- **`## État de l'environnement`** : la ligne `PR :` contient l'URL **et** le numéro (`<url> (#<PR_NUMBER>)`).
- **`## Pour être à jour`** : pointer vers la PR au lieu des commits — `Lis la PR : <url>` puis `Fais \`gh pr view <PR_NUMBER>\` pour voir le détail`.

Après la fence de fermeture, réémettre le trailer strict de `ship` (`✅ Shipped` … `#<PR_NUMBER>`). Le bare `#<PR_NUMBER>` est la toute dernière ligne de la réponse.
