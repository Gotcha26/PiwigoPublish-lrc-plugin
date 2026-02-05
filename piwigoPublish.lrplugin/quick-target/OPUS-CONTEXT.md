# CONTEXTE COMPLET POUR OPUS — PiwigoPublish Optimisation

> Ce fichier est un point de départ autonome. Il contient tout ce qu'Opus a besoin pour reprendre l'audit et l'optimisation sans contexte préalable.

---

## 1. PROJET — Périmètre & Structure

**Répertoire racine :** `D:\Gotcha\Documents\DIY\GitHub\LrC-PublishService\PiwigoPublish-lrc-plugin\piwigoPublish.lrplugin\`

**Nature :** Plugin Lightroom Classic (Lua) pour publiser des photos vers Piwigo (galerie photo open-source).

### Fichiers Lua principaux

| Fichier | Lignes | Rôle |
|---------|--------|------|
| PiwigoAPI.lua | 3 036 | Couche API : toutes les requêtes HTTP vers Piwigo (63 fonctions) |
| PublishTask.lua | 1 459 | Orchestration publication : rendu, upload, sync (25 fonctions) |
| utils.lua | 1 265 | Utilitaires génériques : tags, métadonnées, HTTP helpers (50 fonctions) |
| Init.lua | 99 | Imports globaux LrSDK, pas de fonctions |
| JSON.lua | ~70 KB | Bibliothèque JSON (externe, ne pas modifier) |
| PublishDialogSections.lua | ~13 KB | UI dialogue publication |
| PluginInfoDialogSections.lua | ~6 KB | UI dialogue config plugin |
| PWImportService.lua | ~42 KB | Import depuis Piwigo vers Lightroom |
| UpdateChecker.lua | ~12 KB | Vérification de mise à jour |
| PWExtraOptions.lua | ~5 KB | Options supplémentaires |
| PWCollToSet.lua | ~4.5 KB | Conversion collections |
| PWSendMetadata.lua | ~4.6 KB | Envoi métadonnées |
| PWSetAlbumCover.lua | ~5.6 KB | Couverture album |
| PWStatusManager.lua | ~3 KB | Gestion statut |
| CustomMetadata.lua | ~2.6 KB | Métadonnées personnalisées |
| PublishServiceProvider.lua | ~5.6 KB | Fournisseur service publication |
| PluginInfo.lua | ~1.2 KB | Info plugin |
| Tagset.lua | ~1.5 KB | Gestion tagsets |
| UIHelpers.lua | ~1.9 KB | Helpers UI |
| Info.lua | ~2.4 KB | Info générale |

### Fonctions critiques (cibles d'optimisation)

**PiwigoAPI.lua** — fonctions clés :
- `httpGet` / `httpPost` (local) — toutes les requêtes HTTP
- `PiwigoAPI.login` / `PiwigoAPI.pwConnect` — authentification
- `PiwigoAPI.pwCategoriesGet` / `pwCategoriesGetThis` — récupération albums
- `PiwigoAPI.getTagList` / `PiwigoAPI.createTags` — gestion tags
- `PiwigoAPI.checkPhoto` — vérifie si photo existe déjà
- `PiwigoAPI.associateImageToCategory` — association multi-album
- `PiwigoAPI.updateMetadata` — mise à jour métadonnées individuelle
- `PiwigoAPI.httpPostMultiPart` — upload fichier

**PublishTask.lua** — fonctions clés :
- `PublishTask.processRenderedPhotos` — boucle principale publication
- `PublishTask.processCloneSync` — sync clone
- `PublishTask.deletePhotosFromPublishedCollection` — suppression

**utils.lua** — fonctions clés :
- `utils.tagsToIds` — conversion tags → IDs Piwigo (O(n²) actuel)
- `utils.getPhotoMetadata` — extraction métadonnées photo
- `utils.findExistingPwImageId` — recherche photo existante
- `utils.extract_cookies` / `utils.mergeSplitCookies` — gestion session HTTP

---

## 2. PLAN D'OPTIMISATION — Contexte de l'ancien audit

**Objectif global :** Réduire le temps de publication de **87%** (12 min → 3 min pour 50 photos)

**Structure :** 4 phases, 7 étapes, 5 axes d'optimisation

### Résumé des phases & étapes

| Phase | Étapes | Objectif | Fichiers principaux |
|-------|--------|----------|---------------------|
| 1 — Impact immédiat | 1A, 1B | -35% temps pub | PiwigoAPI.lua, PublishTask.lua |
| 2 — Stabilité & Mémoire | 2A, 2B | -75% mémoire, stable 1000 photos | PiwigoAPI.lua |
| 3 — Perf avancée | 3A, 4A | -95% lookups multi-album | PublishTask.lua |
| 4 — Polish | 5B | -93% getAllTags() calls | utils.lua, PiwigoAPI.lua |

### Détail des étapes

**Étape 1A — CacheManager HTTP**
- Fichier : PiwigoAPI.lua
- Gain : -200 à -400 appels HTTP par session
- Mécanisme : mettre en cache les réponses repeated (getAllCategories, getTagList) avec TTL
- Dépendances : aucune

**Étape 1B — Batch métadonnées**
- Fichiers : PublishTask.lua, PiwigoAPI.lua
- Gain : -50% appels métadonnées (ex: 150 → 60 appels pour 50 photos)
- Mécanisme : file d'attente, flush par lots de 10 via batchUpdateMetadata()
- Dépendances : 1A optionnel

**Étape 2A — Streaming données volumineuses**
- Fichier : PiwigoAPI.lua
- Gain : -75% mémoire peak
- Mécanisme : traiter les catégories un par un au lieu de tout charger en mémoire
- Dépendances : aucune

**Étape 2B — ConnectionPool**
- Fichier : PiwigoAPI.lua
- Gain : -90% overhead session (fini les re-login perpétuels)
- Mécanisme : pool de connexions avec réuse, détection mort après idle
- Dépendances : 2A optionnel

**Étape 3A — Index cache URLs Piwigo**
- Fichier : PublishTask.lua
- Gain : O(1) lookup au lieu de O(n²) pour détecter photos déjà publiées
- Mécanisme : index hashmap pwImageURL → photoId
- Dépendances : 1A

**Étape 4A — Pipeline async rendu/upload**
- Fichier : PublishTask.lua
- Gain : -40% temps total (overlap rendu CPU et upload réseau)
- Mécanisme : démarrer uploads pendant que d'autres photos se rendent encore
- Dépendances : 3A

**Étape 5B — Lazy loading tags + persistance disque**
- Fichiers : utils.lua, PiwigoAPI.lua
- Gain : -93% appels getAllTags()
- Mécanisme : cache disque avec TTL 1h, index O(1) pour tagsToIds
- Dépendances : aucune

### Checkpoints de validation

| Fin Phase | Critère |
|-----------|---------|
| Phase 1 | Publication 50 photos < 8 min (actuellement ~12 min) |
| Phase 2 | Stable sur 1000 photos, mémoire < 40 MB |
| Phase 3 | Multi-album lookup < 0.2 sec pour 100 photos |
| Phase 4 | Tous les tests passing, rapport final confirmant 87% |

---

## 3. ARTEFACTS DE L'ANCIEN AUDIT — Emplacement

Ces fichiers sont dans le même répertoire (`quick-target/`) et sont **toujours valides** comme référence :

| Fichier | Contenu | Utilité pour Opus |
|---------|---------|-------------------|
| SKILL.md | Workflow de suivi par étape, checklists, format de rapport | Guide de bonne conduite étape par étape |
| SETUP-GUIDE.md | Guide interaction, patterns, repères de progression | Comment Julien et Opus travaillent ensemble |
| test-templates.md | Code Lua de benchmark + checklists de régression par étape | Copy-paste pour valider chaque étape |
| memory-setup.txt | Instructions memory (obsolète pour VSCode, info uniquement) | Référence uniquement |

---

## 4. ÉTAT ACTUEL — Aucune étape démarrée

Toutes les étapes sont à l'état **⭕ Non démarré**. Le code source est dans son état original, aucune optimisation n'a été implémentée.

---

## 5. PRÉFÉRENCES DE JULIEN

- Pas d'explication verbose du "pourquoi" — direct, concis
- Diagnostic rapide, pas de remédiation expliquée en détail
- Git : branch `dev`, un commit par étape, merge `main` seulement après Phase 1 validée
- Tests : validation locale dans Lightroom avant commit
- Langue : Français

---

## 6. QUE FAIRE MAINTENANT (pour Opus)

**Option A — Reprendre le plan tel quel :**
Le plan de l'ancien audit est solide. Opus peut démarrer directement avec l'Étape 1A en lisant SKILL.md et test-templates.md comme guide.

**Option B — Auditer d'abord, puis optimiser :**
Si Opus veut vérifier la pertinence du plan avant de coder, il peut faire un audit rapide sur les 3 fichiers clés (PiwigoAPI.lua, PublishTask.lua, utils.lua) pour confirmer que les gains estimés sont réalistes. Cela prendra moins d'un tour de conversation.

**Recommandation : Option B** — un audit rapide d'Opus sur le code actuel va confirmer (ou ajuster) les estimations, puis on démarre Étape 1A immédiatement.
