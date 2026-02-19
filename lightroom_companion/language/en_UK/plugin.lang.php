<?php
// =========================================================================
//  Lightroom Companion — English translations
// =========================================================================

// == TAB NAMES ==
$lang['lrc_tab_video']    = 'Video';
$lang['lrc_tab_server']   = 'Server';
$lang['lrc_tab_settings'] = 'Settings';

// == STATUS BANNER ==
$lang['lrc_video_fully_active']    = 'Video support is fully active';
$lang['lrc_video_fully_active_sub'] = 'Upload enabled &amp; VideoJS plugin active — videos can be published from Lightroom.';
$lang['lrc_video_not_configured']    = 'Video support is not fully configured';
$lang['lrc_video_not_configured_sub'] = 'Check the items below and fix each one.';

// == TAB VIDEO ==
$lang['lrc_section_video_upload'] = 'Video Upload (Piwigo)';
$lang['lrc_upload_status']       = 'Upload status';
$lang['lrc_ready']               = 'Ready';
$lang['lrc_not_configured']      = 'Not configured';
$lang['lrc_all_file_types']      = 'All file types';
$lang['lrc_enabled']             = 'Enabled';
$lang['lrc_disabled']            = 'Disabled';
$lang['lrc_video_extensions']    = 'Video extensions';
$lang['lrc_none_configured']     = 'None configured';
$lang['lrc_enable_video']        = 'Enable Video Support';
$lang['lrc_enable_video_note']   = 'Adds <code>upload_form_all_types = true</code> and video extensions (mp4, m4v, ogg, ogv, webm) to <code>local/config/config.inc.php</code>.';
$lang['lrc_disable_video']       = 'Disable Video Support';
$lang['lrc_disable_video_note']  = 'Removes the Companion block from <code>local/config/config.inc.php</code>. Video uploads will no longer be allowed.';
$lang['lrc_config_not_writable'] = 'Config file is not writable. Add manually to <code>local/config/config.inc.php</code>:';

// == VIDEOJS ==
$lang['lrc_section_videojs']     = 'VideoJS Plugin';
$lang['lrc_plugin']              = 'Plugin';
$lang['lrc_status']              = 'Status';
$lang['lrc_active']              = 'Active';
$lang['lrc_installed_inactive']  = 'Installed but INACTIVE';
$lang['lrc_not_installed']       = 'Not installed';
$lang['lrc_videojs_install_note'] = 'Install and activate the VideoJS plugin from Piwigo administration for in-gallery video playback.';
$lang['lrc_videojs_activate_note'] = 'Activate VideoJS in Piwigo administration (Plugins menu) for video playback to work.';

// == TAB SERVER ==
$lang['lrc_section_media_tools']  = 'Video &amp; Media Tools';
$lang['lrc_ffmpeg_no_note']       = 'Without FFmpeg, videos will upload but Piwigo will not generate a custom thumbnail for them.';
$lang['lrc_section_server_php']   = 'Server &amp; PHP';
$lang['lrc_os']                   = 'OS';
$lang['lrc_web_server']           = 'Web Server';
$lang['lrc_php_version']          = 'PHP Version';
$lang['lrc_exec_available']       = 'exec() available';
$lang['lrc_yes']                  = 'Yes';
$lang['lrc_no']                   = 'No';
$lang['lrc_exec_disabled_note']   = 'exec() is disabled — contact your hosting provider';
$lang['lrc_section_graphics']     = 'Graphics Libraries';
$lang['lrc_not_available']        = 'Not available';
$lang['lrc_section_piwigo']       = 'Piwigo Gallery';
$lang['lrc_version']              = 'Version';
$lang['lrc_guest_theme']          = 'Guest theme';
$lang['lrc_parent']               = 'parent';
$lang['lrc_config_writable']      = 'Config file writable';

// == TAB SETTINGS ==
$lang['lrc_gd_not_available']     = 'GD library not available';
$lang['lrc_gd_not_available_sub'] = 'Thumbnail processing requires the PHP GD extension. Posters will be stored as-is.';
$lang['lrc_section_thumbnail']    = 'Video Thumbnail';
$lang['lrc_max_size']             = 'Max size (px)';
$lang['lrc_longest_side']         = 'longest side';
$lang['lrc_no_upscale']           = 'No upscale';
$lang['lrc_no_enlarge']           = "Don't enlarge small images";
$lang['lrc_section_filmstrip']    = 'Film Strip Effect';
$lang['lrc_filmstrip_label']      = '35mm film border';
$lang['lrc_filmstrip_option']     = 'Add perforated film borders (square output)';
$lang['lrc_filmstrip_note']       = 'The thumbnail becomes square with black letterbox and 35mm-style sprocket holes on the sides.';
$lang['lrc_section_overlays']     = 'Overlays';
$lang['lrc_video_icon']           = 'Video icon (corner)';
$lang['lrc_video_icon_option']    = 'Show video file icon';
$lang['lrc_missing_asset']        = 'missing';
$lang['lrc_icon_position']        = 'Icon position';
$lang['lrc_bottom_right']         = 'Bottom-right';
$lang['lrc_bottom_left']          = 'Bottom-left';
$lang['lrc_play_button']          = 'Play button (center)';
$lang['lrc_play_button_option']   = 'Show play button overlay';
$lang['lrc_play_native_note']     = 'drawn natively, no PNG needed';
$lang['lrc_play_size']            = 'Play button size';
$lang['lrc_play_size_note']       = 'of the shortest side (5–50%)';
$lang['lrc_play_opacity']         = 'Play button opacity';
$lang['lrc_play_opacity_note']    = 'transparency of the overlay (10–100%)';
$lang['lrc_overlay_asset_note']   = 'Place your custom PNG file (with transparency) in the <code>lightroom_companion/assets/</code> folder for the video icon overlay.';
$lang['lrc_save_settings']        = 'Save Settings';
$lang['lrc_settings_saved']       = 'Settings saved.';

// == VIDEO META (picture page) ==
$lang['lrc_video_original']  = 'Video (original)';
$lang['lrc_video_converted'] = 'Video (converted)';
