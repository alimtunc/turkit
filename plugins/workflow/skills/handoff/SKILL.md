---
name: handoff
description: Résume la conversation en cours pour l'envoyer à un autre LLM. Accepte un argument optionnel `ship` pour enchaîner le skill `ship` après le résumé. Usage - /handoff ou /handoff ship
---

# Handoff

Produis un résumé markdown de **cette conversation**, prêt à coller dans un autre LLM pour qu'il reprenne le fil.

## Argument

- **(aucun)** — comportement par défaut : commit + résumé.
- **`ship`** — invoquer `ship` (commit + push + PR + ticket Done) **avant** d'afficher le résumé, pour que le résumé contienne l'URL et le numéro de la PR. Les étapes 1–3 sont déléguées à `ship`.

## Étapes (mode défaut)

1. **Commiter** tous les changements non commités avant de résumer. Suivre les règles de commit du projet (message concis, pas de `Co-Authored-By`). Si rien à commiter, passer à l'étape suivante.
2. **Worktree → branche mère** — Si on est dans un git worktree :
   - Identifier la branche mère (celle depuis laquelle le worktree a été créé).
   - Pousser les commits du worktree vers la branche mère avec `git push origin HEAD:<branche-mère>` ou cherry-pick selon le cas.
   - Sortir du worktree (`ExitWorktree`) pour revenir à l'espace principal.
   - Supprimer le worktree (`git worktree remove <path>`).
   - Vérifier dans l'espace principal que les commits sont bien sur la branche mère (`git log --oneline -5`).
3. **Passer l'issue Linear en Done** — Si une issue Linear est associée à la conversation (identifiant DEV-XXXX dans les commits ou le contexte), la passer au statut "Done" via le MCP Linear (`save_issue` avec `stateId` correspondant à "Done").
4. **Rédiger le résumé** au format défini ci-dessous (section [Format de sortie](#format-de-sortie)). Pointeur final = commit(s) (hash court + branche).
5. **Afficher le résumé.** Respecter strictement le format de sortie — bloc markdown fencé, rien après la fence de fermeture.

## Étapes (mode `ship`)

1. **Préparer le brouillon** du résumé à partir de `git diff` et `git diff --cached` (le commit n'existe pas encore).
2. **Invoquer le skill `ship`** (commit + push + PR + ticket Done). Si `ship` échoue (hook pre-commit, push refusé, etc.), surfacer l'erreur telle quelle et **ne pas** afficher de résumé : le handoff n'est pas final tant que la PR n'est pas ouverte.
3. **Capturer l'URL et le numéro de PR** depuis la sortie de `ship` (dernière ligne `#<PR_NUMBER>`, ligne `PR : <url>`).
4. **Afficher le résumé** avec le pointeur de PR (URL + numéro) à la place du pointeur de commit, dans le bloc markdown fencé.
5. **Réémettre le bloc final de `ship`** juste après la fence de fermeture du résumé (cf. [Format de sortie — mode ship](#mode-ship)). Le bare `#<PR_NUMBER>` reste la toute dernière ligne de la réponse.

## Règles de rédaction

- **Ne pas lister les fichiers modifiés.** Si l'autre LLM a besoin du détail, il lit le commit.
- **Pas de section "Ce qui reste à faire".** Le handoff raconte l'état actuel, pas un backlog.
- **Toujours inclure l'état de l'environnement** : worktree (path / supprimé), branche (poussée ou pas), Linear (statut courant), PR (ouverte avec URL / bundlée / aucune). C'est ce qui dit à l'autre LLM où reprendre.
- **Toujours inclure le résultat des gates** dans "Ce qu'on a fait" : tests (n/n), lint, typecheck, et explicitement noter si la vérif manuelle UI n'a pas été faite.
- Rester factuel et dense : pas de remplissage, pas de reformulation du ticket.

## Format de sortie

Le résumé DOIT être émis dans un **bloc de code markdown fencé** pour rester copiable en un clic. Règles strictes :

- **Une seule fence d'ouverture (` ```markdown `) et une seule fence de fermeture (` ``` `).** Pas de blocs imbriqués.
- **Rien avant la fence d'ouverture.** Aucune phrase d'intro du genre "Voici le résumé :".
- **Rien après la fence de fermeture** en mode défaut. En mode `ship`, seul le trailer de `ship` (voir ci-dessous) suit la fence — aucune autre prose.
- **Toutes les sections du gabarit sont obligatoires**, dans l'ordre. Si une info manque, l'indiquer explicitement (ex. "Linear : aucun ticket associé"), ne pas omettre la section.

### Gabarit (mode défaut)

````
```markdown
# Handoff — <titre du ticket ou sujet>

## Contexte
<sur quoi on bossait, ticket associé>

## Décisions / points importants
- <décision 1>
- <décision 2>

## Ce qu'on a fait
- <résumé fonctionnel>
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

### Mode `ship`

Mêmes sections, avec deux changements :

- **`## État de l'environnement`** : la ligne `PR :` contient l'URL **et** le numéro (`<url> (#<PR_NUMBER>)`).
- **`## Pour être à jour`** : pointer vers la PR au lieu des commits — `Lis la PR : <url>` puis `Fais \`gh pr view <PR_NUMBER>\` pour voir le détail`.

Après la fence de fermeture, réémettre le trailer strict de `ship` :

```
✅ Shipped
- Commit : <short-hash> — <subject>
- Branch : <branch>
- Ticket : <ID> → Done       (or: no tracker detected)
- PR     : <url>

#<PR_NUMBER>
```

Le bare `#<PR_NUMBER>` est la **toute dernière ligne** de la réponse. Rien après.
