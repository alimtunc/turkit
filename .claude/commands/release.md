---
description: Bump la version d'un plugin du marketplace turkit (commit + tag + push). Outil maintainer — ne ship pas aux utilisateurs.
argument-hint: "[plugin] [patch|minor|major]"
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git tag:*), Bash(git push:*), Bash(git add:*), Bash(git commit:*), Bash(git rev-parse:*), Bash(git describe:*), Bash(git fetch:*), Bash(git rev-list:*), Read, Edit
---

# Release

Publie une nouvelle version d'un plugin du marketplace turkit : bump `plugin.json` → entrée CHANGELOG → commit → tag → push.

Le tag suit le format `turkit-<plugin>--v<semver>` (ex : `turkit-workflow--v1.0.3`). C'est ce que lit Claude Code pour proposer la mise à jour aux installations existantes.

**Contexte** : commande maintainer locale au repo turkit. Pas distribuée via le marketplace.

## Arguments

- **plugin** — `workflow` (défaut) ou `react`. Détermine le `plugin.json` et le préfixe du tag.
- **level** — `patch` (défaut), `minor`, ou `major`. Si absent, déduit depuis les commits depuis le dernier tag du plugin.

Exemples : `/release`, `/release react`, `/release workflow minor`.

Argument reçu : $ARGUMENTS

## Étapes

1. **Résoudre le plugin.** Premier argument ou `workflow` par défaut. Le chemin du `plugin.json` est `plugins/<plugin>/.claude-plugin/plugin.json`. Abort si le fichier n'existe pas.

2. **Vérifier l'état git.**
   - Branche courante = `main` (`git rev-parse --abbrev-ref HEAD`). Sinon abort.
   - Working tree propre (`git status --porcelain` vide). Sinon abort en listant les fichiers modifiés.
   - À jour avec `origin/main` : `git fetch origin main` puis vérifier que `git rev-list HEAD..origin/main --count` = 0. Sinon demander de `git pull` d'abord.

3. **Lire la version courante** depuis `plugin.json` (champ `version`).

4. **Trouver le dernier tag du plugin** : `git describe --tags --abbrev=0 --match 'turkit-<plugin>--v*'`. Si aucun tag (premier release du plugin), utiliser le premier commit comme base.

5. **Lister les commits depuis ce tag**, filtrés sur le plugin :
   ```
   git log <last-tag>..HEAD --pretty=format:'%h %s' -- plugins/<plugin>/
   ```
   Si vide, abort : "Aucun commit touchant `plugins/<plugin>/` depuis `<last-tag>`. Rien à publier."

6. **Déduire le niveau** (uniquement si l'argument n'est pas fourni) en parcourant les sujets de commits :
   - Un sujet contient `!:` ou un commit contient `BREAKING CHANGE:` dans le body → **major**.
   - Un sujet préfixé `feat(` ou `feat:` → **minor**.
   - Sinon → **patch**.

7. **Calculer la nouvelle version** depuis la courante via SemVer. Major reset minor/patch à 0 ; minor reset patch à 0.

8. **Afficher le résumé et demander confirmation** :
   - Plugin, ancien tag, version courante → nouvelle version, niveau (et "auto-détecté" ou "forcé").
   - Liste compacte des commits inclus (hash court + sujet).
   - Demander : "OK pour publier ?"

9. **Mettre à jour `plugin.json`** : remplacer le champ `version` par la nouvelle valeur. Préserver le formatage exact du fichier (indentation, trailing newline).

10. **Mettre à jour `CHANGELOG.md`** : insérer une nouvelle section **en tête** (après le titre `# Changelog` et le préambule, avant la section précédente la plus récente) :
    ```
    ## turkit-<plugin> v<new> — <YYYY-MM-DD>

    ### Added
    - <feat commits, sans le préfixe `feat(scope):`>

    ### Fixed
    - <fix commits>

    ### Changed
    - <refactor / chore / docs commits qui apportent une modif fonctionnelle>
    ```
    Omettre les sous-sections vides. Si tous les commits sont purement `chore:` de maintenance interne (release prep, bump), mettre une seule ligne sous **Changed**.

11. **Commiter** :
    ```
    git add plugins/<plugin>/.claude-plugin/plugin.json CHANGELOG.md
    git commit -m "chore(<plugin>): release v<new>"
    ```
    Subject only, pas de `Co-Authored-By`, pas de `--no-verify`.

12. **Tag** : `git tag turkit-<plugin>--v<new>`.

13. **Push** : `git push --follow-tags origin main`. Le `--follow-tags` envoie le commit ET le tag annoté dans la même opération.

14. **Reporter** :
    - Nouveau tag publié, URL GitHub vers le tag (`https://github.com/alimtunc/turkit/releases/tag/turkit-<plugin>--v<new>`).
    - Rappel : les installations existantes se mettent à jour au prochain démarrage de Claude Code (le marketplace turkit a `autoUpdate: true`). Pour forcer maintenant : `/plugin` → update.

## Guardrails

- Jamais `--force`, jamais `--no-verify`, jamais `--no-gpg-sign`.
- Jamais amender un commit déjà poussé. Si un pre-commit hook échoue : fix l'erreur, re-stage, **nouveau** commit.
- Si le tag existe déjà localement : abort. Ne pas écraser un tag publié.
- Si le push échoue (rejected, hook), surfacer l'erreur brute. Ne pas réessayer en force.
- Toujours opérer depuis `main`. Refuser sur tout autre branche, même si la version est à bumper.

## Reprise sur erreur

- **Commit créé mais push échoué** : le commit local existe avec le tag. Surfacer l'état (`git log -1`, `git tag --points-at HEAD`) et laisser l'opérateur décider (`git push --follow-tags` une fois la cause corrigée). Ne **pas** reset.
- **`plugin.json` modifié mais commit pas encore créé** : l'erreur s'est produite avant l'étape 11. Laisser les changements en working tree, ne pas les annuler ; l'opérateur peut relancer `/release` après correction.
