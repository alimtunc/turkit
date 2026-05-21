---
name: shipoff
description: Ship la branche (commit + push + PR + ticket Done) puis produit un résumé de handoff pour passer la main à un autre LLM. Raccourci pour `/handoff ship`. Usage - /shipoff
disable-model-invocation: true
---

# Shipoff

Raccourci d'un seul mot pour `/handoff ship` : ship la branche **et** produit le résumé de handoff dans la foulée.

Ce skill ne réimplémente rien — il invoque le skill `handoff` avec l'argument `ship`. Toute la logique (rédaction du résumé sur le diff non commité, exécution de `ship` pour le commit/push/PR/ticket, puis affichage du résumé avec l'URL de la PR) vit dans `handoff`.

## Étapes

1. **Invoquer `handoff` avec l'argument `ship`.** Suivre son flux exactement — ne pas dupliquer ses garde-fous ici.

2. **Rien d'autre.** Si `handoff` ou `ship` échouent (hook pre-commit, push refusé, gh CLI manquant…), surfacer l'erreur telle quelle. Ne pas masquer l'échec derrière un message générique.

## Quand utiliser `shipoff` plutôt que `handoff ship`

Pure question d'ergonomie : un seul mot à taper. Le résultat est strictement identique.

## Quand **ne pas** utiliser `shipoff`

- **Pas de ship souhaité** (juste un résumé pour passer la main) → utiliser `/handoff` sans argument.
- **Vérification manuelle pas faite.** `ship` suppose que l'opérateur a déjà validé le changement à la main. Si ce n'est pas le cas, faire la vérif d'abord (voir `/test-instructions` ou `/verify`).
- **Sur la branche de base** (`main` / `master`). `ship` abortera de toute façon — autant le savoir avant.
