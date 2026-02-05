# SETUP COMPLET : Suivre le Plan d'Optimisation

## À faire maintenant (5 min)

### 1. Activer la Skill de Suivi
La skill **piwigo-optimization-tracking** est prête à l'emploi.
Elle se déclenche automatiquement si tu mentionnes :
- "Étape 1A", "Début Étape", "Commençant", "done"
- "Validation", "next phase", "checkpoint"

### 2. Initialiser la Memory (one-time setup)

```
Ouvre : Settings → Profile → Memory
Puis copie/exécute les commandes du fichier memory-setup.txt (10 lignes minimum, 19 optionnel)
```

Résultat : Je me souviendrai du plan global, des phases, et des préférences entre conversations.

### 3. Garder à Proximité

Pendant les 4 semaines, garde open :
- `optimisation_rapport.md` → Code snippets & gains
- `piwigo-optimization-tracking/SKILL.md` → Checklists & workflows
- `test-templates.md` → Tests de validation

Julien peut dropper : `"Je démarre Étape 1A"` → Je charge automatiquement le contexte.

---

## Workflow Typique d'une Étape (15-30 min avec moi)

### Avant (tu fais seul)
```
1. Lire le code snippet pour l'étape dans optimisation_rapport.md
2. Identifier les fichiers à modifier
3. Implémenter le code localement
4. Tester sur Lightroom (basic smoke test)
```

### Pendant (si tu as besoin d'aide)
```
Dis : "Help, Étape 1A - [courte description du problème]"

Je vais :
  ✓ Tracer le code existant
  ✓ Pointer la source du bug (pas d'explication longue)
  ✓ Montrer où corriger
  ✓ Laisser la correction à toi
```

### Après (validation avec moi)
```
Dis : "Étape 1A complétée"

Je vais :
  ✓ Afficher template de benchmark
  ✓ Créer checklist de régression
  ✓ Demander metrics (combien d'appels HTTP maintenant ?)
  ✓ Valider pas de breaking changes
  ✓ Mettre à jour memory & plan
  ✓ Initialiser Étape suivante
```

---

## Commandes Rapides (Reference)

| Tu dis | Je fais |
|--------|---------|
| "Début Étape XY" | Code snippet + checklist validation + tests |
| "Aidez-moi, [problème]" | Tracer le bug, pas d'explication |
| "Étape XY done" | Rapport perf, validation checklist, next steps |
| "Phase N complète" | Résumé gains, Phase N+1 setup |
| "État du plan ?" | Show progress, blockers, next milestone |
| "Rollback Étape XY" | Revert checklist, root cause, next action |

---

## Repères de Progression

### Fin Phase 1 (Semaine 1)
- ✅ Étape 1A & 1B complétées
- ✅ Publication 50 photos < 8 minutes (actuellement ~12)
- ✅ HTTP calls down de 60%+
- ⏳ Prêt pour Phase 2

### Fin Phase 2 (Semaine 2)
- ✅ Étape 2A & 2B complétées
- ✅ Mémoire < 40 MB (1000 photos)
- ✅ Pas de crash risk sur gros projets
- ⏳ Prêt pour Phase 3

### Fin Phase 3 (Semaine 3)
- ✅ Étape 3A & 4A complétées
- ✅ Multi-album lookup < 0.2 sec
- ✅ Total perf ~50% du temps initial
- ⏳ Prêt pour Phase 4

### Fin Phase 4 (Semaine 4)
- ✅ Étape 5B complétée
- ✅ Full integration tests passing
- ✅ Rapport final : 87% speedup confirmé
- ✅ Ready for production / release

---

## Structures de Fichiers

```
PiwigoPublish-lrc-plugin (dev branch)
├── piwigoPublish.lrplugin/
│   ├── PiwigoAPI.lua          ← Étape 1A, 1B, 2A, 2B, 5B
│   ├── PublishTask.lua         ← Étape 1B, 3A, 4A
│   ├── utils.lua              ← Étape 5B
│   ├── Init.lua                ← Étape 1A (require CacheManager)
│   └── ... (other files)
└── tests/ (optional)
    ├── TestHarness.lua        ← Benchmarking
    ├── IntegrationTest.lua    ← Full cycle
    └── ...

Mon context:
├── optimisation_rapport.md     ← Code snippets & gains
├── piwigo-optimization-tracking/SKILL.md ← Checklists
├── test-templates.md           ← Test code templates
└── memory-setup.txt            ← Memory initialization
```

---

## Patterns d'Interaction

### Pattern 1 : Étape Simple (Pas de Problème)

```
Toi  : "Début Étape 1A"
Moi  : [Affiche code snippet + checklist + expected gains]
Toi  : [Implémentes localement, testes]
Toi  : "1A done"
Moi  : [Rapport perf + validation checklist]
Toi  : [Fournis metrics]
Moi  : [Valide, init Étape 1B]
```

Durée totale : 30-45 min

### Pattern 2 : Étape avec Issue

```
Toi  : "Début Étape 2B"
Moi  : [Code snippet]
Toi  : [Implémentes, tests sur Lightroom]
Toi  : "Bug : Connection pool not reusing, keeps logging in"
Moi  : [Tracer le code]
      ConnectionPool.getConnection() retourne toujours new conn
      Vérifier : ConnectionPool.connections[key] accessible avant création ?
      [Pointe le bug : clé mal formée ou pas de check d'existence]
Toi  : [Corriges]
Toi  : "Fixed"
Moi  : [Rapport perf]
```

Durée totale : 45-60 min

### Pattern 3 : Blockers Entre Phases

```
Toi  : "Phase 1 done, results good"
Moi  : [Résumé gains Phase 1]
      [Affiche Phase 2 overview & dépendances]
      [Si Phase 2 dépend de Phase 1 → all good]
      [Si Phase 2 indépendant → can start in parallel]
Toi  : [Décide ordre & timing]
```

---

## Tips pour Aller Vite

1. **Commit par étape** : Chaque étape = 1 commit distinct, avant fin de phase
2. **Test local d'abord** : Valide sur Lightroom avant de demander review
3. **Logs !** : Ajoute log:info() pour tracer les chemins critiques (aide pour validation)
4. **Cache invalidation** : Pense à nettoyer les caches quand settings changent
5. **Git branches** : `dev` pour toutes les étapes, merge dans `main` seulement après Phase 1 entière

---

## SOS : Si tu es Bloqué

### Problème : "Je ne sais pas si c'est assez rapide"
→ Utilise le TestHarness.lua template pour benchmark
→ Compare avant/après avec chiffres concrets

### Problème : "Je casse quelque chose"
→ Rollback, dis "Rollback Étape XY"
→ Je générerai une checklist de revert + root cause

### Problème : "Phase N prend trop de temps"
→ On peut skip une étape (ex: 4A si trop complexe)
→ Focus sur les gains critiques (1A, 2A, 5B)

### Problème : "Je veux changer l'ordre des étapes"
→ Dis moi quelles dépendances tu vois
→ Je validerai si reordering OK

---

## Checklist de Démarrage (Aujourd'hui)

- [ ] Lire optimisation_rapport.md (sections 1-2)
- [ ] Lire piwigo-optimization-tracking/SKILL.md (workflow standard)
- [ ] Initialiser memory edits via memory-setup.txt (10-15 lignes)
- [ ] Marquer Étape 1A comme "Prête à commencer" dans memory
- [ ] Demain matin : "Début Étape 1A"

---

## Success Criteria (À la Fin)

```
Publication de 50 photos avec métadonnées :
  AVANT : 12-14 minutes
  APRÈS : 2-3 minutes
  GAIN : 87%+ réduction

Memory profile (1000 photos) :
  AVANT : 120+ MB
  APRÈS : < 40 MB
  
Stabilité :
  AVANT : Crash risk moyen
  APRÈS : Très stable, production-ready
```

---

Maintenant c'est à toi. 😊

Quand tu es prêt : `"Commençant Étape 1A"`

