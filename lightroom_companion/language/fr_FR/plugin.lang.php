<?php
// =========================================================================
//  Lightroom Companion — Traductions françaises
// =========================================================================

// == ONGLETS ==
$lang['lrc_tab_video']    = 'Vidéo';
$lang['lrc_tab_server']   = 'Serveur';
$lang['lrc_tab_settings'] = 'Réglages';

// == BANNIÈRE STATUT ==
$lang['lrc_video_fully_active']    = 'Le support vidéo est pleinement actif';
$lang['lrc_video_fully_active_sub'] = 'Upload activé &amp; plugin VideoJS actif — les vidéos peuvent être publiées depuis Lightroom.';
$lang['lrc_video_not_configured']    = 'Le support vidéo n\'est pas entièrement configuré';
$lang['lrc_video_not_configured_sub'] = 'Vérifiez les éléments ci-dessous et corrigez chacun.';

// == ONGLET VIDÉO ==
$lang['lrc_section_video_upload'] = 'Upload vidéo (Piwigo)';
$lang['lrc_upload_status']       = 'Statut upload';
$lang['lrc_ready']               = 'Prêt';
$lang['lrc_not_configured']      = 'Non configuré';
$lang['lrc_all_file_types']      = 'Tous types de fichiers';
$lang['lrc_enabled']             = 'Activé';
$lang['lrc_disabled']            = 'Désactivé';
$lang['lrc_video_extensions']    = 'Extensions vidéo';
$lang['lrc_none_configured']     = 'Aucune configurée';
$lang['lrc_enable_video']        = 'Activer le support vidéo';
$lang['lrc_enable_video_note']   = 'Ajoute <code>upload_form_all_types = true</code> et les extensions vidéo (mp4, m4v, ogg, ogv, webm) dans <code>local/config/config.inc.php</code>.';
$lang['lrc_disable_video']       = 'Désactiver le support vidéo';
$lang['lrc_disable_video_note']  = 'Supprime le bloc Companion de <code>local/config/config.inc.php</code>. L\'upload de vidéos ne sera plus autorisé.';
$lang['lrc_config_not_writable'] = 'Le fichier de configuration n\'est pas modifiable. Ajoutez manuellement dans <code>local/config/config.inc.php</code> :';

// == VIDEOJS ==
$lang['lrc_section_videojs']     = 'Plugin VideoJS';
$lang['lrc_plugin']              = 'Plugin';
$lang['lrc_status']              = 'Statut';
$lang['lrc_active']              = 'Actif';
$lang['lrc_installed_inactive']  = 'Installé mais INACTIF';
$lang['lrc_not_installed']       = 'Non installé';
$lang['lrc_videojs_install_note'] = 'Installez et activez le plugin VideoJS depuis l\'administration Piwigo pour la lecture vidéo dans la galerie.';
$lang['lrc_videojs_activate_note'] = 'Activez VideoJS dans l\'administration Piwigo (menu Plugins) pour que la lecture vidéo fonctionne.';

// == ONGLET SERVEUR ==
$lang['lrc_section_media_tools']  = 'Outils vidéo &amp; média';
$lang['lrc_ffmpeg_no_note']       = 'Sans FFmpeg, les vidéos seront uploadées mais Piwigo ne générera pas de vignette personnalisée.';
$lang['lrc_section_server_php']   = 'Serveur &amp; PHP';
$lang['lrc_os']                   = 'OS';
$lang['lrc_web_server']           = 'Serveur web';
$lang['lrc_php_version']          = 'Version PHP';
$lang['lrc_exec_available']       = 'exec() disponible';
$lang['lrc_yes']                  = 'Oui';
$lang['lrc_no']                   = 'Non';
$lang['lrc_exec_disabled_note']   = 'exec() est désactivé — contactez votre hébergeur';
$lang['lrc_section_graphics']     = 'Bibliothèques graphiques';
$lang['lrc_not_available']        = 'Non disponible';
$lang['lrc_section_piwigo']       = 'Galerie Piwigo';
$lang['lrc_version']              = 'Version';
$lang['lrc_guest_theme']          = 'Thème visiteur';
$lang['lrc_parent']               = 'parent';
$lang['lrc_config_writable']      = 'Fichier config modifiable';

// == ONGLET RÉGLAGES ==
$lang['lrc_gd_not_available']     = 'Bibliothèque GD non disponible';
$lang['lrc_gd_not_available_sub'] = 'Le traitement des vignettes nécessite l\'extension PHP GD. Les posters seront stockés tels quels.';
$lang['lrc_section_thumbnail']    = 'Vignette vidéo';
$lang['lrc_max_size']             = 'Taille max (px)';
$lang['lrc_longest_side']         = 'côté le plus long';
$lang['lrc_no_upscale']           = 'Pas d\'agrandissement';
$lang['lrc_no_enlarge']           = 'Ne pas agrandir les petites images';
$lang['lrc_section_filmstrip']    = 'Effet pellicule';
$lang['lrc_filmstrip_label']      = 'Bordure pellicule 35mm';
$lang['lrc_filmstrip_option']     = 'Ajouter des bordures perforées (sortie carrée)';
$lang['lrc_filmstrip_note']       = 'La vignette devient carrée avec un letterbox noir et des perforations style 35mm sur les côtés.';
$lang['lrc_section_overlays']     = 'Superpositions';
$lang['lrc_video_icon']           = 'Icône vidéo (coin)';
$lang['lrc_video_icon_option']    = 'Afficher l\'icône fichier vidéo';
$lang['lrc_missing_asset']        = 'manquant';
$lang['lrc_icon_position']        = 'Position de l\'icône';
$lang['lrc_bottom_right']         = 'Bas-droite';
$lang['lrc_bottom_left']          = 'Bas-gauche';
$lang['lrc_play_button']          = 'Bouton lecture (centre)';
$lang['lrc_play_button_option']   = 'Afficher le bouton lecture';
$lang['lrc_play_native_note']     = 'dessiné nativement, pas de PNG nécessaire';
$lang['lrc_play_size']            = 'Taille bouton lecture';
$lang['lrc_play_size_note']       = 'du côté le plus court (5–50%)';
$lang['lrc_play_opacity']         = 'Opacité bouton lecture';
$lang['lrc_play_opacity_note']    = 'transparence de la superposition (10–100%)';
$lang['lrc_overlay_asset_note']   = 'Placez votre fichier PNG personnalisé (avec transparence) dans le dossier <code>lightroom_companion/assets/</code> pour la superposition d\'icône vidéo.';
$lang['lrc_save_settings']        = 'Enregistrer les réglages';
$lang['lrc_settings_saved']       = 'Réglages enregistrés.';

// == META VIDÉO (page photo) ==
$lang['lrc_video_original']  = 'Vidéo (originale)';
$lang['lrc_video_converted'] = 'Vidéo (convertie)';
