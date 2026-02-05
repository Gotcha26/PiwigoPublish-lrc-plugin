---
name: piwigo-optimization-tracking
description: Suivi structuré du plan d'optimisation PiwigoPublish en 4 phases. À utiliser pour tracker la progression des implémentations, valider les étapes, générer des rapports de test, et maintenir la cohérence du refactoring. Déclenche automatiquement quand Julien signale du travail sur le plan d'optimisation ou demande un checkpoint.
---

# Suivi du Plan d'Optimisation PiwigoPublish

## Contexte du Plan

**Objectif global** : Réduire le temps de publication de 87% (12 min → 3 min pour 50 photos)

**Structure** : 4 phases sur 4 semaines, 5 axes d'optimisation indépendants

**Gains attendus par phase** :
- Phase 1 : -35% temps (2-3h)
- Phase 2 : -75% mémoire, stabilité +95% (2-3h)
- Phase 3 : -95% lookups multi-album (3-4h)
- Phase 4 : Polish & tests (2h)

---

## Workflow Standard pour Chaque Étape

### 1. Initialisation de l'Étape
Quand Julien signale qu'il démarre une étape (ex: "Commençant Étape 1A"):

```
✓ Afficher le code snippet de la SKILL.md pour l'étape
✓ Rappeler les fichiers à modifier (ex: PiwigoAPI.lua, PublishTask.lua)
✓ Lister les points de test après implémentation
✓ Créer un checklist de validation
```

### 2. Suivi Intra-Étape
Pendant le travail (si Julien demande help/debugging):

```
✓ Diagnostic direct : tracer code existant
✓ Vérifier intégration avec ancien code
✓ Pas d'explication "pourquoi ça marche" sauf si erreur persiste
✓ Pointer la source de bug, laisser la correction à Julien
```

### 3. Validation Post-Étape
Quand Julien signale "Étape XY complétée":

```
✓ Générer template de test avec données test
✓ Vérifier pas de régressions (backward compat)
✓ Produire rapport de perf avant/après
✓ Valider intégration avec étapes précédentes
✓ Mettre à jour l'état global du plan
```

### 4. Transition Inter-Phase
Avant de passer de Phase N à Phase N+1:

```
✓ Résumer les étapes complétées
✓ Identifier dépendances vers phase suivante
✓ Évaluer impact cumulé sur performance
✓ Recommander optimisations d'ordre (si pertinent)
```

---

## État du Plan (À mettre à jour)

### Phase 1 : Impact Immédiat
- [ ] **Étape 1A** : CacheManager pour HTTP
  - Fichiers : PiwigoAPI.lua
  - Gain : -200-400 appels HTTP par session
  - Statut : ⭕ Non démarré
  
- [ ] **Étape 1B** : Regroupement métadonnées + batchUpdateMetadata()
  - Fichiers : PublishTask.lua, PiwigoAPI.lua
  - Gain : -50% appels métadonnées
  - Dépend de : 1A (optionnel)
  - Statut : ⭕ Non démarré

**Checkpoint Phase 1** : Publication 50 photos < 8 min (actuellement ~12 min)

---

### Phase 2 : Stabilité & Mémoire
- [ ] **Étape 2A** : Streaming des données volumineuses
  - Fichiers : PiwigoAPI.lua
  - Gain : -75% mémoire
  - Dépend de : Rien
  - Statut : ⭕ Non démarré

- [ ] **Étape 2B** : ConnectionPool au lieu de reconnexions
  - Fichiers : PiwigoAPI.lua
  - Gain : -90% overhead session
  - Dépend de : 2A (optionnel)
  - Statut : ⭕ Non démarré

**Checkpoint Phase 2** : Plugin stable sur 1000 photos, mémoire < 40 MB

---

### Phase 3 : Perf Avancée
- [ ] **Étape 3A** : Index de cache pour URLs Piwigo
  - Fichiers : PublishTask.lua
  - Gain : O(n) lookup au lieu de O(n²)
  - Dépend de : 1A
  - Statut : ⭕ Non démarré

- [ ] **Étape 4A** : Async rendu/upload pipeline (si applicable pour Lua)
  - Fichiers : PublishTask.lua
  - Gain : -40% temps total
  - Dépend de : 3A
  - Statut : ⭕ Non démarré

**Checkpoint Phase 3** : Multi-album lookup < 0.2 sec pour 100 photos

---

### Phase 4 : Polish
- [ ] **Étape 5B** : Lazy loading tags + persistance
  - Fichiers : utils.lua, PiwigoAPI.lua
  - Gain : -93% getAllTags() calls
  - Dépend de : Rien
  - Statut : ⭕ Non démarré

- [ ] Tests intégration & monitoring
  - Création suite de tests
  - Benchmark avant/après
  - Documentation des changements

**Checkpoint Phase 4** : All tests passing, rapport final de perf

---

## Checklist de Validation par Étape

### Template de Validation (À dupliquer pour chaque étape)

```markdown
## Étape X.Y : [Nom]

### Code Review
- [ ] Pas de code dupliqué
- [ ] Pas de dépendances circulaires
- [ ] Backward compatible (pas de breaking changes)
- [ ] Gestion d'erreurs (try/catch ou logs)
- [ ] Pas de fuites mémoire (tables nettoyées)

### Tests Fonctionnels
- [ ] Cas nominal (happy path)
- [ ] Cas de bornes (vide, très gros)
- [ ] Cas d'erreur (API down, timeout)
- [ ] Intégration avec code existant

### Performance
- [ ] Métrique avant : [X]
- [ ] Métrique après : [Y]
- [ ] Gain observé : [Y/X]
- [ ] Correspond à l'objectif ?

### Régression
- [ ] Aucune perte de feature
- [ ] Cache properly cleared on settings change
- [ ] Logs OK (debug messages sensibles)

### Status Final
- [ ] ✅ Validée & mergée
- [ ] 🔄 Wip, bloquée par
- [ ] ⚠️ Issues identifiées : [Quoi]
```

---

## Format de Rapport Post-Étape

Quand Julien signale "Étape XY done, ready for validation":

```
### 📊 Rapport Étape X.Y : [Nom]

**Durée réelle** : [X] heures vs [Y] heures estimée

**Code modifié**:
- PiwigoAPI.lua : +[N] lignes, -[M] lignes
- [Autre fichier] : ...

**Métriques**:
| Métrique | Avant | Après | Gain |
|----------|-------|-------|------|
| [X] | [A] | [B] | [Pct]% |

**Issues découvertes** : [Aucun | List]

**Actions post-validation** : [Quoi passer à côté avant merge]

**Ready for Phase 2** ? ✅ Yes / ⏳ Wait for [Bloquant]
```

---

## Commandes Rapides pour Julien

### Phase actuelle
`"Quelle étape atteinte ?"` → Afficher checkpoint et étapes complétées

### Démarrage étape
`"Début Étape 2A"` → Code snippet + checklist + tests à faire

### Validation
`"2A done"` → Template rapport + validation checklist

### Debug
`"Problème ici [code]"` → Tracer le code, pointer la source, pas d'explication

### Transition
`"Phase 1 complète"` → Résumé gains, dépendances Phase 2, temps estimé

### Rollback
`"Rollback Étape XY"` → Revert checklist + raison du rollback + action suivante

---

## Notes de Contexte Permanentes

- **Framework** : Lightroom Classic SDK (Lua)
- **Versions cibles** : Plugin v20260122.1+
- **Préférence** : Pas d'explication "pourquoi" sauf si bug
- **Priorité** : Correction > Explication > Performance mentale
- **Testing** : Validations locales avec Lightroom avant commit
- **Versioning** : Chaque étape = commit distinct, avant fin de phase
- **Git** : Branch `dev`, pas de merge dans `main` tant que Phase 1 non validée

---

## Quick Reference : Fichiers Clés à Modifier par Étape

| Étape | Fichiers Primaires | Fichiers Secondaires |
|-------|-------------------|----------------------|
| 1A | PiwigoAPI.lua | Init.lua (require) |
| 1B | PublishTask.lua | PiwigoAPI.lua |
| 2A | PiwigoAPI.lua | PublishTask.lua |
| 2B | PiwigoAPI.lua | PublishTask.lua |
| 3A | PublishTask.lua | PiwigoAPI.lua (batch lookup) |
| 4A | PublishTask.lua | - |
| 5B | utils.lua | PiwigoAPI.lua |

