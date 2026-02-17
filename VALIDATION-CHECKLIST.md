# PiwigoPublish — Checklist de validation manuelle (Phase 5D)

> Validation à effectuer dans Lightroom Classic avec un service Piwigo de test.
> Cocher chaque cas avant de considérer une release stable.

---

## Prérequis

- [ ] Piwigo installé et accessible (serveur local ou distant)
- [ ] Plugin `lightroom-companion` installé et activé sur Piwigo
- [ ] Video Toolkit installé (`python video_toolkit.py --mode probe` retourne du JSON)
- [ ] FFmpeg disponible (auto-détecté ou configuré)
- [ ] Au moins 3 photos JPG de test + 2 vidéos MP4 de test dans le catalogue LrC

---

## 1. Configuration du service

| # | Scénario | Résultat attendu | OK |
|---|----------|-----------------|-----|
| 1.1 | Configurer le service avec URL/user/pass valides | Connexion verte dans le panneau | ☐ |
| 1.2 | Activer "Enable Video Toolkit" | Sections preset et outils apparaissent | ☐ |
| 1.3 | Laisser les chemins outils vides → cliquer "Check Tools" | Détection auto + dialog "auto-detected at: ..." | ☐ |
| 1.4 | Saisir un chemin Python invalide → cliquer "Check Tools" | Dialog d'erreur avec commande d'installation | ☐ |
| 1.5 | Sélectionner preset "Medium (720p)" comme défaut service | Valeur persistée à la réouverture du manager | ☐ |

---

## 2. Publication de photos seules (régression)

| # | Scénario | Résultat attendu | OK |
|---|----------|-----------------|-----|
| 2.1 | Publier 3 photos JPG dans un album | Photos visibles dans Piwigo, marquées "Published" dans LrC | ☐ |
| 2.2 | Re-publier une photo modifiée (métadonnées) | Mise à jour titre/description sur Piwigo sans erreur | ☐ |
| 2.3 | Supprimer une photo publiée dans LrC | Photo supprimée de Piwigo | ☐ |
| 2.4 | Publier avec filtre de mots-clés actif | Seules les photos correspondant au filtre sont publiées | ☐ |

---

## 3. Publication de vidéos — premier envoi

| # | Scénario | Résultat attendu | OK |
|---|----------|-----------------|-----|
| 3.1 | Publier 1 vidéo MP4 (preset Medium) | Variante 720p visible dans Piwigo, poster affiché, vidéo marquée "Published" | ☐ |
| 3.2 | Vérifier les métadonnées custom dans LrC | `pwVideoPreset = "medium"`, `pwImageURL` rempli, `pwUploadDate` correct | ☐ |
| 3.3 | Publier 2 vidéos en même batch | Les deux uploadées, progression affichée pour chaque | ☐ |
| 3.4 | Publier batch mixte 2 photos + 1 vidéo | Photos et vidéo toutes publiées, types traités séparément | ☐ |
| 3.5 | Vérifier le poster dans Piwigo | Miniature personnalisée visible (pas l'icône générique vidéo) | ☐ |

---

## 4. Publication de vidéos — republication

| # | Scénario | Résultat attendu | OK |
|---|----------|-----------------|-----|
| 4.1 | Re-publier une vidéo sans changement (même preset) | Metadata-only : pas de re-upload, titre/description mis à jour | ☐ |
| 4.2 | Changer le preset service (Medium → Large) puis republier | Re-encode forcé, nouvelle variante 1080p uploadée | ☐ |
| 4.3 | Vérifier que `pwVideoPreset` est mis à jour après 4.2 | Valeur = "large" dans les métadonnées custom LrC | ☐ |
| 4.4 | Re-publier sans changement après 4.2 | Metadata-only (pas de re-encode), log confirme | ☐ |

---

## 5. Override preset par collection (5C)

| # | Scénario | Résultat attendu | OK |
|---|----------|-----------------|-----|
| 5.1 | Ouvrir les settings d'un album → section "Video Preset Override" visible | Popup "Use service default" + 6 presets | ☐ |
| 5.2 | Sélectionner "Small (480p)" comme override → publier une vidéo | Variante 480p créée et uploadée (pas 720p) | ☐ |
| 5.3 | Vérifier `pwVideoPreset = "small"` dans les métadonnées | Valeur correcte stockée | ☐ |
| 5.4 | Revenir à "Use service default" → republier | Re-encode avec le preset service (Medium), pas Small | ☐ |
| 5.5 | Deux albums avec presets différents, publier une vidéo dans chacun | Chaque album utilise son preset respectif | ☐ |

---

## 6. Cas d'erreur et gestion (5A)

| # | Scénario | Résultat attendu | OK |
|---|----------|-----------------|-----|
| 6.1 | Publier vidéo avec plugin Companion désactivé sur Piwigo | Dialog "Companion plugin not installed", vidéos retirées du batch, photos publiées | ☐ |
| 6.2 | Publier vidéo avec Video Toolkit désactivé dans les settings | Vidéos ignorées silencieusement (ou message), photos publiées | ☐ |
| 6.3 | Annuler pendant le traitement toolkit (barre de progression) | Dialog "Publication cancelled during video processing" | ☐ |
| 6.4 | Simuler échec toolkit (Python introuvable après config) | Dialog "Video Toolkit Error (exit code X)" | ☐ |
| 6.5 | Publier vidéo metadata-only avec image_id manquant | Dialog warning avec nom du fichier concerné | ☐ |

---

## 7. Upload chunked (vidéos volumineuses)

| # | Scénario | Résultat attendu | OK |
|---|----------|-----------------|-----|
| 7.1 | Configurer server max = 50 MB, publier vidéo de 80 MB | Upload chunked déclenché (log "→ chunked upload"), vidéo visible sur Piwigo | ☐ |
| 7.2 | Publier vidéo sous la limite | Upload standard addSimple (log "→ addSimple upload") | ☐ |

---

## 8. Auto-détection outils (5B)

| # | Scénario | Résultat attendu | OK |
|---|----------|-----------------|-----|
| 8.1 | Vider le champ Python + cliquer "Check Tools" | Python auto-détecté, chemin affiché dans le dialog | ☐ |
| 8.2 | Publier une vidéo sans aucun chemin configuré | Python auto-détecté et utilisé, publication réussie | ☐ |
| 8.3 | Vérifier le log plugin (`LrC/Plug-in Log`) | Ligne "python resolved to: C:/..." présente | ☐ |

---

## Notes de test

- Logs plugin LrC : **Aide → Plug-in Log** → chercher `PublishTask`
- Dossier `.vtk/` créé à côté des vidéos originales (variantes + cache hash)
- En cas d'échec inattendu, joindre le log complet au rapport de bug
