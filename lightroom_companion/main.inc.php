<?php
/*
Plugin Name: Lightroom Companion
Version: 1.5.0
Description: Companion plugin for the PiwigoPublish Lightroom plugin. Exposes server diagnostics, provides automatic video upload configuration, extended video metadata storage, and includes an administration page.
Plugin URI: https://github.com/your-repo/piwigo-companion
Author: Gotcha
Has Settings: webmaster
*/

defined('PHPWG_ROOT_PATH') or die('Hacking attempt!');

/**
 * Register admin menu entry and API methods
 */
add_event_handler('get_admin_plugin_menu_links', 'companion_admin_menu');
add_event_handler('ws_add_methods', 'companion_add_methods');
add_event_handler('init', 'companion_install');
add_event_handler('loc_end_picture', 'companion_picture_video_meta');

function companion_admin_menu($menu)
{
    array_push($menu, array(
        'NAME' => 'Lightroom Companion',
        'URL'  => get_admin_plugin_menu_link(__DIR__ . '/admin.php'),
    ));
    return $menu;
}

function companion_add_methods($arr)
{
    $service = &$arr[0];

    $service->addMethod(
        'pwg.companion.getConfig',
        'companion_get_config',
        array(),
        'Returns server configuration: PHP, upload limits, graphics libs, FFmpeg, video readiness.',
        null,
        array('admin_only' => true)
    );

    $service->addMethod(
        'pwg.companion.enableVideoSupport',
        'companion_enable_video_support',
        array(),
        'Enables video upload support by writing upload_form_all_types and file_ext to local config.',
        null,
        array('admin_only' => true)
    );

    $service->addMethod(
        'pwg.companion.disableVideoSupport',
        'companion_disable_video_support',
        array(),
        'Removes the Companion video block from local/config/config.inc.php.',
        null,
        array('admin_only' => true)
    );

    $service->addMethod(
        'pwg.companion.setRepresentative',
        'companion_set_representative',
        array(
            'image_id' => array(
                'default'  => null,
                'type'     => WS_TYPE_INT,
                'info'     => 'Piwigo image/video ID',
            ),
        ),
        'Upload a poster/thumbnail image as the representative for a video.',
        null,
        array('admin_only' => true)
    );

    $service->addMethod(
        'pwg.companion.setVideoInfo',
        'companion_set_video_info',
        array(
            'image_id' => array(
                'default'  => null,
                'type'     => WS_TYPE_INT,
                'info'     => 'Piwigo image/video ID',
            ),
            'width' => array(
                'default'  => null,
                'type'     => WS_TYPE_INT,
                'info'     => 'Video width in pixels',
            ),
            'height' => array(
                'default'  => null,
                'type'     => WS_TYPE_INT,
                'info'     => 'Video height in pixels',
            ),
            'filesize' => array(
                'default'  => null,
                'type'     => WS_TYPE_INT,
                'info'     => 'Video file size in bytes (optional)',
            ),
        ),
        'Sets video dimensions and optional filesize in the Piwigo images table.',
        null,
        array('admin_only' => true)
    );

    $service->addMethod(
        'pwg.companion.setVideoMeta',
        'companion_set_video_meta',
        array(
            'image_id'     => array('default' => null, 'type' => WS_TYPE_INT),
            'orig_width'   => array('default' => null, 'type' => WS_TYPE_INT),
            'orig_height'  => array('default' => null, 'type' => WS_TYPE_INT),
            'orig_fps'     => array('default' => null),
            'orig_bitrate' => array('default' => null, 'type' => WS_TYPE_INT),
            'orig_codec'   => array('default' => null),
            'orig_format'  => array('default' => null),
            'orig_filesize'=> array('default' => null, 'type' => WS_TYPE_INT),
            'conv_width'   => array('default' => null, 'type' => WS_TYPE_INT),
            'conv_height'  => array('default' => null, 'type' => WS_TYPE_INT),
            'conv_fps'     => array('default' => null),
            'conv_bitrate' => array('default' => null, 'type' => WS_TYPE_INT),
            'conv_codec'   => array('default' => null),
            'conv_format'  => array('default' => null),
            'conv_filesize'=> array('default' => null, 'type' => WS_TYPE_INT),
        ),
        'Store extended video metadata (source + VTK variant) for a Piwigo image.',
        null,
        array('admin_only' => true)
    );
}

// =========================================================================
//  pwg.companion.getConfig
// =========================================================================
function companion_get_config($params, &$service)
{
    $result = array();

    // ----- PHP -----
    $disabled_functions = array_map('trim', explode(',', ini_get('disable_functions')));
    $exec_available = function_exists('exec') && !in_array('exec', $disabled_functions);

    $result['php'] = array(
        'version'              => PHP_VERSION,
        'memory_limit'         => ini_get('memory_limit'),
        'upload_max_filesize'  => ini_get('upload_max_filesize'),
        'post_max_size'        => ini_get('post_max_size'),
        'max_execution_time'   => ini_get('max_execution_time'),
        'max_input_time'       => ini_get('max_input_time'),
        'max_file_uploads'     => ini_get('max_file_uploads'),
        'exec_available'       => $exec_available,
        'disabled_functions'   => $exec_available ? '' : ini_get('disable_functions'),
    );

    // ----- Graphics library -----
    $gfx = array('gd' => false, 'imagick' => false);

    if (function_exists('gd_info'))
    {
        $gd = gd_info();
        $gfx['gd'] = array(
            'version' => isset($gd['GD Version']) ? $gd['GD Version'] : 'unknown',
            'jpeg'    => !empty($gd['JPEG Support']),
            'png'     => !empty($gd['PNG Support']),
            'webp'    => !empty($gd['WebP Support']),
        );
    }

    if (extension_loaded('imagick'))
    {
        try {
            $im = new Imagick();
            $ver = Imagick::getVersion();
            $gfx['imagick'] = array(
                'version' => isset($ver['versionString']) ? $ver['versionString'] : 'unknown',
            );
        } catch (Exception $e) {
            $gfx['imagick'] = array('version' => 'error: ' . $e->getMessage());
        }
    }

    $result['graphics'] = $gfx;

    // ----- CLI tools (FFmpeg, ExifTool, MediaInfo) -----
    if ($exec_available)
    {
        $result['ffmpeg']    = companion_detect_tool('ffmpeg', '-version');
        $result['ffprobe']   = companion_detect_tool('ffprobe', '-version');
        $result['exiftool']  = companion_detect_tool('exiftool', '-ver');
        $result['mediainfo'] = companion_detect_tool('mediainfo', '--Version');
    }
    else
    {
        $notice = 'exec() is disabled by PHP configuration';
        $result['ffmpeg']    = array('installed' => false, 'notice' => $notice);
        $result['ffprobe']   = array('installed' => false, 'notice' => $notice);
        $result['exiftool']  = array('installed' => false, 'notice' => $notice);
        $result['mediainfo'] = array('installed' => false, 'notice' => $notice);
    }

    // ----- Piwigo config (video-relevant) -----
    global $conf;

    $upload_all = isset($conf['upload_form_all_types']) ? (bool)$conf['upload_form_all_types'] : false;
    $file_ext   = isset($conf['file_ext']) ? $conf['file_ext'] : array();
    $pic_ext    = isset($conf['picture_ext']) ? $conf['picture_ext'] : array();

    // Check for video extensions
    $video_exts = array('mp4', 'm4v', 'ogg', 'ogv', 'webm', 'webmv', 'mpg', 'mpeg', 'mov', 'avi');
    $found_video_exts = array_values(array_intersect($file_ext, $video_exts));

    $result['piwigo'] = array(
        'version'               => PHPWG_VERSION,
        'upload_form_all_types' => $upload_all,
        'file_ext'              => $file_ext,
        'picture_ext'           => $pic_ext,
        'video_ext_configured'  => $found_video_exts,
        'video_ready'           => $upload_all && !empty($found_video_exts),
        'local_config_writable' => companion_is_local_config_writable(),
    );

    // ----- OS -----
    $result['server'] = array(
        'os'       => PHP_OS,
        'software' => isset($_SERVER['SERVER_SOFTWARE']) ? $_SERVER['SERVER_SOFTWARE'] : 'unknown',
    );

    return $result;
}

// =========================================================================
//  pwg.companion.enableVideoSupport
// =========================================================================
function companion_enable_video_support($params, &$service)
{
    global $conf;

    $config_path = PHPWG_ROOT_PATH . 'local/config/config.inc.php';

    // Check if already configured
    $upload_all = isset($conf['upload_form_all_types']) ? (bool)$conf['upload_form_all_types'] : false;
    $file_ext   = isset($conf['file_ext']) ? $conf['file_ext'] : array();
    $video_exts = array('mp4', 'm4v', 'ogg', 'ogv', 'webm');
    $found = array_intersect($file_ext, $video_exts);

    if ($upload_all && count($found) >= count($video_exts))
    {
        return array(
            'status' => 'already_configured',
            'message' => 'Video support is already enabled.',
        );
    }

    // Check writable
    if (!companion_is_local_config_writable())
    {
        return array(
            'status' => 'error',
            'message' => 'Cannot write to ' . $config_path . '. Check file permissions.',
        );
    }

    // Read current file content
    $content = '';
    if (file_exists($config_path))
    {
        $content = file_get_contents($config_path);
    }

    // Build lines to append
    $lines_to_add = array();
    $lines_to_add[] = '';
    $lines_to_add[] = '// --- PiwigoPublish Companion: video upload support ---';

    if (!$upload_all)
    {
        $lines_to_add[] = "\$conf['upload_form_all_types'] = true;";
    }

    // Always write file_ext with merge to ensure video extensions are present
    $lines_to_add[] = "\$conf['file_ext'] = array_merge(";
    $lines_to_add[] = "    \$conf['picture_ext'],";
    $lines_to_add[] = "    array('mp4', 'm4v', 'ogg', 'ogv', 'webm')";
    $lines_to_add[] = ");";

    // Check if file has PHP opening tag
    $php_open_tag = '<' . '?php';
    $php_close_tag = '?' . '>';
    if (empty($content) || strpos($content, $php_open_tag) === false)
    {
        $content = $php_open_tag . "\n" . implode("\n", $lines_to_add) . "\n";
    }
    else
    {
        /* Remove trailing close-tag if present (we'll leave the file open) */
        $content = rtrim($content);
        if (substr($content, -2) === $php_close_tag)
        {
            $content = rtrim(substr($content, 0, -2));
        }
        $content .= "\n" . implode("\n", $lines_to_add) . "\n";
    }

    // Write
    $written = @file_put_contents($config_path, $content);
    if ($written === false)
    {
        return array(
            'status' => 'error',
            'message' => 'Failed to write to ' . $config_path,
        );
    }

    return array(
        'status' => 'ok',
        'message' => 'Video support has been enabled. Video extensions (mp4, m4v, ogg, ogv, webm) are now allowed.',
    );
}

// =========================================================================
//  pwg.companion.disableVideoSupport
// =========================================================================
function companion_disable_video_support($params, &$service)
{
    $config_path = PHPWG_ROOT_PATH . 'local/config/config.inc.php';
    $marker      = '// --- PiwigoPublish Companion: video upload support ---';

    if (!file_exists($config_path))
    {
        return array('status' => 'error', 'message' => 'Config file not found.');
    }

    if (!is_writable($config_path))
    {
        return array('status' => 'error', 'message' => 'Config file is not writable.');
    }

    $content = file_get_contents($config_path);

    $pos = strpos($content, $marker);
    if ($pos === false)
    {
        return array('status' => 'already_configured', 'message' => 'Companion block not found — nothing to remove.');
    }

    // Remove from the blank line just before the marker to the end of the block.
    // The block ends at the last semicolon line after the marker.
    // Strategy: find the newline before $pos (the blank separator line), remove everything from there to end of block.
    // We remove: optional preceding \n, then marker line + all following lines until the next empty line or EOF.
    $block_start = $pos;
    // Walk back to include the preceding blank line (\n\n before marker)
    if ($block_start >= 2 && substr($content, $block_start - 1, 1) === "\n")
        $block_start--;

    // Find end of block: scan forward until blank line or end of string
    $block_end = $pos + strlen($marker);
    $len = strlen($content);
    while ($block_end < $len)
    {
        $nl = strpos($content, "\n", $block_end);
        if ($nl === false) { $block_end = $len; break; }
        $line = substr($content, $block_end, $nl - $block_end + 1);
        $block_end = $nl + 1;
        if (trim($line) === '') break;  // blank line = end of block
    }

    $content = substr($content, 0, $block_start) . substr($content, $block_end);
    $content = rtrim($content) . "\n";

    $written = @file_put_contents($config_path, $content);
    if ($written === false)
    {
        return array('status' => 'error', 'message' => 'Failed to write to ' . $config_path);
    }

    return array('status' => 'ok', 'message' => 'Video support has been disabled. The Companion block has been removed from local/config/config.inc.php.');
}

/**
 * Check if the Companion video block is present in local config.
 */
function companion_has_video_block()
{
    $config_path = PHPWG_ROOT_PATH . 'local/config/config.inc.php';
    if (!file_exists($config_path)) return false;
    return strpos(file_get_contents($config_path), '// --- PiwigoPublish Companion: video upload support ---') !== false;
}

// =========================================================================
//  pwg.companion.setRepresentative
// =========================================================================
function companion_set_representative($params, &$service)
{
    global $conf;

    $image_id = (int)$params['image_id'];
    if ($image_id <= 0)
    {
        return new PwgError(WS_ERR_INVALID_PARAM, 'image_id must be a positive integer');
    }

    // Verify image exists
    $query = 'SELECT id, path FROM ' . IMAGES_TABLE . ' WHERE id = ' . $image_id . ';';
    $result = pwg_query($query);
    $row = pwg_db_fetch_assoc($result);
    if (!$row)
    {
        return new PwgError(404, 'Image ' . $image_id . ' not found');
    }

    // Expect an uploaded file named 'file'
    if (empty($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK)
    {
        $err = isset($_FILES['file']['error']) ? $_FILES['file']['error'] : 'no file';
        return new PwgError(WS_ERR_INVALID_PARAM, 'No valid file uploaded (error: ' . $err . ')');
    }

    // Determine storage directory from existing image path
    // path is relative to PHPWG_ROOT_PATH, e.g. "upload/2024/01/01/2024010...jpg"
    $image_dir = PHPWG_ROOT_PATH . dirname($row['path']);
    if (!is_dir($image_dir))
    {
        return new PwgError(500, 'Image directory not found: ' . $image_dir);
    }

    // Build representative filename: same basename, extension = uploaded file extension
    $uploaded_ext = strtolower(pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION));
    if (!in_array($uploaded_ext, array('jpg', 'jpeg', 'png', 'webp')))
    {
        return new PwgError(WS_ERR_INVALID_PARAM, 'Poster must be jpg, jpeg, png or webp');
    }

    // Piwigo representative: stored in pwg_representative/ subdirectory
    $image_basename = pathinfo($row['path'], PATHINFO_FILENAME);
    $representative_filename = $image_basename . '.' . $uploaded_ext;
    $representative_dir = $image_dir . '/pwg_representative';
    if (!is_dir($representative_dir))
    {
        @mkdir($representative_dir, 0755, true);
    }
    $representative_path = $representative_dir . '/' . $representative_filename;

    if (!move_uploaded_file($_FILES['file']['tmp_name'], $representative_path))
    {
        return new PwgError(500, 'Failed to move uploaded poster to ' . $representative_path);
    }

    // Process thumbnail: resize + film strip + overlays (if GD available)
    companion_process_representative($representative_path);

    // Invalidate Piwigo derivative cache for this image
    $query = 'UPDATE ' . IMAGES_TABLE
        . " SET representative_ext = '" . pwg_db_real_escape_string($uploaded_ext) . "'"
        . ' WHERE id = ' . $image_id . ';';
    pwg_query($query);

    // Delete cached derivatives so Piwigo regenerates thumbnails
    $image_path = PHPWG_ROOT_PATH . $row['path'];
    if (function_exists('delete_element_derivatives'))
    {
        $element_info = array('id' => $image_id, 'path' => $row['path']);
        delete_element_derivatives($element_info);
    }

    return array(
        'status'                  => 'ok',
        'image_id'                => $image_id,
        'representative_ext'      => $uploaded_ext,
        'representative_path'     => $representative_filename,
    );
}

// =========================================================================
//  pwg.companion.setVideoInfo
// =========================================================================
function companion_set_video_info($params, &$service)
{
    $image_id = (int)$params['image_id'];
    if ($image_id <= 0)
    {
        return new PwgError(WS_ERR_INVALID_PARAM, 'image_id must be a positive integer');
    }

    // Verify image exists
    $query = 'SELECT id FROM ' . IMAGES_TABLE . ' WHERE id = ' . $image_id . ';';
    $result = pwg_query($query);
    $row = pwg_db_fetch_assoc($result);
    if (!$row)
    {
        return new PwgError(404, 'Image ' . $image_id . ' not found');
    }

    // Build SET clause from provided parameters
    $updates = array();

    if (isset($params['width']) && $params['width'] !== null)
    {
        $width = (int)$params['width'];
        if ($width > 0) $updates[] = 'width = ' . $width;
    }

    if (isset($params['height']) && $params['height'] !== null)
    {
        $height = (int)$params['height'];
        if ($height > 0) $updates[] = 'height = ' . $height;
    }

    if (isset($params['filesize']) && $params['filesize'] !== null)
    {
        // Piwigo stores filesize in KB in the images table
        $filesize_bytes = (int)$params['filesize'];
        if ($filesize_bytes > 0)
        {
            $filesize_kb = (int)ceil($filesize_bytes / 1024);
            $updates[] = 'filesize = ' . $filesize_kb;
        }
    }

    if (empty($updates))
    {
        return new PwgError(WS_ERR_INVALID_PARAM, 'At least one of width, height, or filesize must be provided');
    }

    $query = 'UPDATE ' . IMAGES_TABLE
        . ' SET ' . implode(', ', $updates)
        . ' WHERE id = ' . $image_id . ';';
    pwg_query($query);

    return array(
        'status'   => 'ok',
        'image_id' => $image_id,
        'updated'  => $updates,
    );
}

// =========================================================================
//  Database install (CREATE TABLE IF NOT EXISTS on init)
// =========================================================================
function companion_install()
{
    global $prefixeTable, $conf;

    // Use a version flag to avoid running CREATE TABLE on every page load.
    // Only run migrations when the version changes.
    $current_version = '1.4.0';
    $installed_version = isset($conf['companion_version']) ? $conf['companion_version'] : '';

    if ($installed_version === $current_version) return;

    // --- Video metadata table ---
    $table = $prefixeTable . 'companion_video_meta';
    $query = 'CREATE TABLE IF NOT EXISTS ' . $table . ' (
        image_id      INT UNSIGNED    NOT NULL,
        orig_width    SMALLINT UNSIGNED        DEFAULT NULL,
        orig_height   SMALLINT UNSIGNED        DEFAULT NULL,
        orig_fps      DECIMAL(6,3)             DEFAULT NULL,
        orig_bitrate  INT UNSIGNED             DEFAULT NULL,
        orig_codec    VARCHAR(20)              DEFAULT NULL,
        orig_format   VARCHAR(10)              DEFAULT NULL,
        orig_filesize BIGINT UNSIGNED          DEFAULT NULL,
        conv_width    SMALLINT UNSIGNED        DEFAULT NULL,
        conv_height   SMALLINT UNSIGNED        DEFAULT NULL,
        conv_fps      DECIMAL(6,3)             DEFAULT NULL,
        conv_bitrate  INT UNSIGNED             DEFAULT NULL,
        conv_codec    VARCHAR(20)              DEFAULT NULL,
        conv_format   VARCHAR(10)              DEFAULT NULL,
        conv_filesize BIGINT UNSIGNED          DEFAULT NULL,
        updated_at    DATETIME                 DEFAULT NULL,
        PRIMARY KEY (image_id)
    ) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;';
    pwg_query($query);

    // --- Plugin config (default values) ---
    if (!isset($conf['companion_config']))
    {
        $default_config = array(
            'thumb_max_size'    => 350,
            'thumb_no_upscale'  => true,
            'film_strip'        => false,
            'overlay_video_icon'=> false,
            'overlay_video_pos' => 'bottom-right',
            'overlay_play'      => false,
            'overlay_play_size'    => 20,   // % du côté le plus court
            'overlay_play_opacity' => 100,  // 0-100
        );
        conf_update_param('companion_config', json_encode($default_config));
        $conf['companion_config'] = json_encode($default_config);
    }

    // Mark installed version
    conf_update_param('companion_version', $current_version);
    $conf['companion_version'] = $current_version;
}

/**
 * Read a single config value from companion_config JSON
 */
function companion_get_config_value($key, $default = null)
{
    global $conf;
    if (!isset($conf['companion_config'])) return $default;
    $cfg = json_decode($conf['companion_config'], true);
    return (is_array($cfg) && array_key_exists($key, $cfg)) ? $cfg[$key] : $default;
}

/**
 * Read all companion config as array
 */
function companion_get_all_config()
{
    global $conf;
    $defaults = array(
        'thumb_max_size'    => 350,
        'thumb_no_upscale'  => true,
        'film_strip'        => false,
        'overlay_video_icon'  => false,
        'overlay_video_pos'   => 'bottom-right',
        'overlay_play'        => false,
        'overlay_play_size'   => 20,
        'overlay_play_opacity'=> 100,
    );
    if (!isset($conf['companion_config'])) return $defaults;
    $cfg = json_decode($conf['companion_config'], true);
    if (!is_array($cfg)) return $defaults;
    return array_merge($defaults, $cfg);
}

// =========================================================================
//  pwg.companion.setVideoMeta
// =========================================================================
function companion_set_video_meta($params, &$service)
{
    global $prefixeTable;

    $image_id = (int)$params['image_id'];
    if ($image_id <= 0)
    {
        return new PwgError(WS_ERR_INVALID_PARAM, 'image_id must be a positive integer');
    }

    // Verify image exists
    $query = 'SELECT id FROM ' . IMAGES_TABLE . ' WHERE id = ' . $image_id . ';';
    $result = pwg_query($query);
    if (!pwg_db_fetch_assoc($result))
    {
        return new PwgError(404, 'Image ' . $image_id . ' not found');
    }

    $fields = array(
        'orig_width', 'orig_height', 'orig_fps', 'orig_bitrate',
        'orig_codec', 'orig_format', 'orig_filesize',
        'conv_width', 'conv_height', 'conv_fps', 'conv_bitrate',
        'conv_codec', 'conv_format', 'conv_filesize',
    );
    $str_fields = array('orig_codec', 'orig_format', 'conv_codec', 'conv_format');

    $insert_cols  = array('image_id');
    $insert_vals  = array($image_id);
    $update_parts = array();

    foreach ($fields as $field)
    {
        if (isset($params[$field]) && $params[$field] !== null && $params[$field] !== '')
        {
            $insert_cols[] = $field;
            if (in_array($field, $str_fields))
            {
                $val = "'" . pwg_db_real_escape_string($params[$field]) . "'";
            }
            else
            {
                $val = (float)$params[$field];
            }
            $insert_vals[]  = $val;
            $update_parts[] = $field . ' = VALUES(' . $field . ')';
        }
    }

    $update_parts[] = "updated_at = NOW()";

    $table = $prefixeTable . 'companion_video_meta';
    $query = 'INSERT INTO ' . $table
        . ' (' . implode(', ', $insert_cols) . ')'
        . ' VALUES (' . implode(', ', $insert_vals) . ')'
        . ' ON DUPLICATE KEY UPDATE ' . implode(', ', $update_parts) . ';';
    pwg_query($query);

    return array('status' => 'ok', 'image_id' => $image_id);
}

// =========================================================================
//  Hook affichage picture.php — métadonnées vidéo étendues
// =========================================================================
function companion_picture_video_meta()
{
    global $template, $page, $prefixeTable;

    if (!isset($page['image_id'])) return;

    $image_id = (int)$page['image_id'];
    $table = $prefixeTable . 'companion_video_meta';
    $query = 'SELECT * FROM ' . $table . ' WHERE image_id = ' . $image_id . ';';
    $result = pwg_query($query);
    $row = pwg_db_fetch_assoc($result);
    if (!$row) return;

    $orig = companion_format_video_line($row, 'orig');
    $conv = companion_format_video_line($row, 'conv');

    $template->assign(array(
        'VTK_VIDEO_ORIG' => $orig,
        'VTK_VIDEO_CONV' => $conv,
    ));

    // Injection strategy based on parent theme
    $parent = companion_get_parent_theme();
    switch ($parent)
    {
        case 'bootstrap_darkroom':
            $layout = companion_get_bdr_layout();
            if ($layout === 'sidebar')
            {
                $template->set_prefilter('picture', 'companion_inject_sidebar');
            }
            else
            {
                $template->set_prefilter('picture', 'companion_inject_cards');
            }
            break;
        case 'default':
        case 'elegant':
        case 'smartpocket':
            $template->set_prefilter('picture', 'companion_inject_default');
            break;
        default:
            // Try BDR cards first, fall back to default if anchor not found
            $template->set_prefilter('picture', 'companion_inject_auto');
            break;
    }
}

function companion_get_public_theme()
{
    // user_id = 2 = guest dans Piwigo (convention interne fixe)
    $query = "SELECT theme FROM " . USER_INFOS_TABLE . " WHERE user_id = 2 LIMIT 1;";
    $result = pwg_query($query);
    if ($result)
    {
        $row = pwg_db_fetch_assoc($result);
        if ($row && !empty($row['theme']))
            return $row['theme'];
    }
    return 'default';
}

function companion_get_parent_theme()
{
    $theme = companion_get_public_theme();
    $themeconf_path = PHPWG_ROOT_PATH . 'themes/' . $theme . '/themeconf.inc.php';
    if (file_exists($themeconf_path))
    {
        $themeconf = array();
        include($themeconf_path);
        if (isset($themeconf['parent']))
        {
            return $themeconf['parent'];
        }
    }
    return $theme;
}

function companion_get_bdr_layout()
{
    global $conf;

    if (!isset($conf['bootstrap_darkroom']))
    {
        return 'cards';
    }

    $bdr = json_decode($conf['bootstrap_darkroom'], true);
    if (is_array($bdr) && isset($bdr['picture_info'])
        && in_array($bdr['picture_info'], array('sidebar', 'cards', 'tabs')))
    {
        return $bdr['picture_info'];
    }

    return 'cards';
}

function companion_inject_cards($content, &$smarty)
{
    $search = '{if isset($VTK_VIDEO_ORIG)}';
    // Already injected? Don't double-inject.
    if (strpos($content, $search) !== false) return $content;

    $anchor = '<div id="info-content"';
    $pos = strpos($content, $anchor);
    if ($pos === false) return $content;

    // Find end of this opening tag
    $end = strpos($content, '>', $pos);
    if ($end === false) return $content;

    $inject = '
{if isset($VTK_VIDEO_ORIG)}
        <div id="VtkVideoInfo" class="imageInfo">
          <dl class="row mb-0">
            <dt class="col-sm-5">{\'Video (original)\'|translate}</dt>
            <dd class="col-sm-7">{$VTK_VIDEO_ORIG}</dd>
          </dl>
          <dl class="row mb-0">
            <dt class="col-sm-5">{\'Video (converted)\'|translate}</dt>
            <dd class="col-sm-7">{$VTK_VIDEO_CONV}</dd>
          </dl>
        </div>
{/if}';

    return substr($content, 0, $end + 1) . $inject . substr($content, $end + 1);
}

function companion_inject_sidebar($content, &$smarty)
{
    $search = '{if isset($VTK_VIDEO_ORIG)}';
    if (strpos($content, $search) !== false) return $content;

    $anchor = '<div id="info-content"';
    $pos = strpos($content, $anchor);
    if ($pos === false) return $content;

    $end = strpos($content, '>', $pos);
    if ($end === false) return $content;

    $inject = '
{if isset($VTK_VIDEO_ORIG)}
            <div id="VtkVideoInfo" class="imageInfo">
                <dt>{\'Video (original)\'|translate}</dt>
                <dd>{$VTK_VIDEO_ORIG}</dd>
                <dt>{\'Video (converted)\'|translate}</dt>
                <dd>{$VTK_VIDEO_CONV}</dd>
            </div>
{/if}';

    return substr($content, 0, $end + 1) . $inject . substr($content, $end + 1);
}

function companion_inject_default($content, &$smarty)
{
    $search = '{if isset($VTK_VIDEO_ORIG)}';
    if (strpos($content, $search) !== false) return $content;

    // Piwigo default/elegant/smartpocket: inject inside <dl id="standard" class="imageInfoTable">
    $anchor = '<dl id="standard" class="imageInfoTable">';
    $pos = strpos($content, $anchor);
    if ($pos === false) return $content;

    $inject_pos = $pos + strlen($anchor);

    $inject = '
{if isset($VTK_VIDEO_ORIG)}
  <div id="VtkVideoOrig" class="imageInfo">
    <dt>{\'Video (original)\'|translate}</dt>
    <dd>{$VTK_VIDEO_ORIG}</dd>
  </div>
  <div id="VtkVideoConv" class="imageInfo">
    <dt>{\'Video (converted)\'|translate}</dt>
    <dd>{$VTK_VIDEO_CONV}</dd>
  </div>
{/if}';

    return substr($content, 0, $inject_pos) . $inject . substr($content, $inject_pos);
}

function companion_inject_auto($content, &$smarty)
{
    // Try BDR cards anchor first
    if (strpos($content, '<div id="info-content"') !== false)
    {
        return companion_inject_cards($content, $smarty);
    }
    // Fallback to default theme anchor
    if (strpos($content, '<dl id="standard"') !== false)
    {
        return companion_inject_default($content, $smarty);
    }
    // No known anchor found — return unchanged
    return $content;
}

function companion_format_video_line($row, $prefix)
{
    $parts = array();

    $w = (int)($row[$prefix . '_width']  ?? 0);
    $h = (int)($row[$prefix . '_height'] ?? 0);
    if ($w > 0 && $h > 0) $parts[] = $w . "\xc3\x97" . $h;

    $fps = (float)($row[$prefix . '_fps'] ?? 0);
    if ($fps > 0) $parts[] = rtrim(rtrim(number_format($fps, 3, '.', ''), '0'), '.') . ' fps';

    $kbps = (int)($row[$prefix . '_bitrate'] ?? 0);
    if ($kbps > 0)
    {
        $parts[] = $kbps >= 1000
            ? '@' . number_format($kbps / 1000, 1) . ' Mbps'
            : '@' . $kbps . ' kbps';
    }

    $codec = trim($row[$prefix . '_codec'] ?? '');
    if ($codec !== '') $parts[] = strtoupper($codec);

    $fmt = trim($row[$prefix . '_format'] ?? '');
    if ($fmt !== '') $parts[] = strtolower($fmt);

    $bytes = (int)($row[$prefix . '_filesize'] ?? 0);
    if ($bytes > 0)
    {
        $mb = $bytes / (1024 * 1024);
        $parts[] = '(' . ($mb >= 1
            ? number_format($mb, 0, ',', ' ') . ' Mo'
            : number_format($bytes / 1024, 0, ',', ' ') . ' Ko') . ')';
    }

    return implode('&ensp;&ensp;', $parts);
}

// =========================================================================
//  Thumbnail processing (GD)
// =========================================================================

/**
 * Process a representative image: resize, film strip, overlays.
 * Modifies the file in place. Requires GD.
 */
function companion_process_representative($path)
{
    if (!function_exists('imagecreatetruecolor')) return;
    if (!file_exists($path)) return;

    $cfg = companion_get_all_config();

    // Load source image
    $ext = strtolower(pathinfo($path, PATHINFO_EXTENSION));
    $src = companion_gd_load($path, $ext);
    if (!$src) return;

    $src_w = imagesx($src);
    $src_h = imagesy($src);

    // --- 1. Resize ---
    $max = (int)$cfg['thumb_max_size'];
    if ($max <= 0) $max = 350;

    $longest = max($src_w, $src_h);
    if ($longest > $max || !$cfg['thumb_no_upscale'])
    {
        if ($longest > $max)
        {
            $ratio = $max / $longest;
            $new_w = (int)round($src_w * $ratio);
            $new_h = (int)round($src_h * $ratio);
            $resized = imagecreatetruecolor($new_w, $new_h);
            imagecopyresampled($resized, $src, 0, 0, 0, 0, $new_w, $new_h, $src_w, $src_h);
            imagedestroy($src);
            $src = $resized;
            $src_w = $new_w;
            $src_h = $new_h;
        }
    }

    // --- 2. Film strip (creates a square image) ---
    if ($cfg['film_strip'])
    {
        $src = companion_gd_film_strip($src, $src_w, $src_h);
        $src_w = imagesx($src);
        $src_h = imagesy($src);
    }

    // --- 3. Overlay: video icon ---
    if ($cfg['overlay_video_icon'])
    {
        $icon_path = dirname(__FILE__) . '/assets/video-icon.png';
        if (file_exists($icon_path))
        {
            $icon = imagecreatefrompng($icon_path);
            if ($icon)
            {
                $icon_size = (int)round(min($src_w, $src_h) * 0.20);
                $icon_w = imagesx($icon);
                $icon_h = imagesy($icon);
                $scale = $icon_size / max($icon_w, $icon_h);
                $scaled_w = (int)round($icon_w * $scale);
                $scaled_h = (int)round($icon_h * $scale);

                $scaled_icon = imagecreatetruecolor($scaled_w, $scaled_h);
                imagealphablending($scaled_icon, false);
                imagesavealpha($scaled_icon, true);
                $trans = imagecolorallocatealpha($scaled_icon, 0, 0, 0, 127);
                imagefilledrectangle($scaled_icon, 0, 0, $scaled_w, $scaled_h, $trans);
                imagecopyresampled($scaled_icon, $icon, 0, 0, 0, 0, $scaled_w, $scaled_h, $icon_w, $icon_h);
                imagedestroy($icon);

                $margin = (int)round(min($src_w, $src_h) * 0.04);
                $pos = $cfg['overlay_video_pos'];
                if ($pos === 'bottom-left')
                {
                    $dx = $margin;
                }
                else
                {
                    $dx = $src_w - $scaled_w - $margin;
                }
                $dy = $src_h - $scaled_h - $margin;

                imagealphablending($src, true);
                imagecopy($src, $scaled_icon, $dx, $dy, 0, 0, $scaled_w, $scaled_h);
                imagedestroy($scaled_icon);
            }
        }
    }

    // --- 4. Overlay: play button (center, drawn natively in GD) ---
    if ($cfg['overlay_play'])
    {
        $size_pct    = isset($cfg['overlay_play_size'])    ? (int)$cfg['overlay_play_size']    : 20;
        $opacity_pct = isset($cfg['overlay_play_opacity']) ? (int)$cfg['overlay_play_opacity'] : 70;

        $btn = companion_gd_play_button(
            (int)round(min($src_w, $src_h) * ($size_pct / 100.0)),
            $opacity_pct
        );
        if ($btn)
        {
            $btn_w = imagesx($btn);
            $btn_h = imagesy($btn);
            $dx = (int)round(($src_w - $btn_w) / 2);
            $dy = (int)round(($src_h - $btn_h) / 2);
            imagealphablending($src, true);
            imagecopy($src, $btn, $dx, $dy, 0, 0, $btn_w, $btn_h);
            imagedestroy($btn);
        }
    }

    // --- 5. Save ---
    imagejpeg($src, $path, 90);
    imagedestroy($src);
}

/**
 * Load an image via GD from path + extension
 */
function companion_gd_load($path, $ext)
{
    switch ($ext)
    {
        case 'jpg': case 'jpeg':
            return @imagecreatefromjpeg($path);
        case 'png':
            return @imagecreatefrompng($path);
        case 'webp':
            if (function_exists('imagecreatefromwebp'))
                return @imagecreatefromwebp($path);
            return false;
        default:
            return false;
    }
}

/**
 * Apply 35mm film strip effect.
 * Returns a new square GD resource with perforated borders.
 */
function companion_gd_film_strip($src, $src_w, $src_h)
{
    // Strip width = 12% of the longest side
    $side = max($src_w, $src_h);
    $strip_w = (int)round($side * 0.12);

    // Final canvas is square: image width + 2 strips, height = max(src_h, src_w + 2*strip)
    $canvas_w = $src_w + 2 * $strip_w;
    $canvas_h = max($src_h, $canvas_w);
    // Make it square
    $sq = max($canvas_w, $canvas_h);

    $canvas = imagecreatetruecolor($sq, $sq);
    $black = imagecolorallocate($canvas, 0, 0, 0);
    imagefilledrectangle($canvas, 0, 0, $sq - 1, $sq - 1, $black);

    // Film strip background (very dark gray)
    $film_color = imagecolorallocate($canvas, 26, 26, 26);
    // Left strip
    imagefilledrectangle($canvas, 0, 0, $strip_w - 1, $sq - 1, $film_color);
    // Right strip
    imagefilledrectangle($canvas, $sq - $strip_w, 0, $sq - 1, $sq - 1, $film_color);

    // Draw sprocket holes
    $hole_w = (int)round($strip_w * 0.45);
    $hole_h = (int)round($hole_w * 0.7);
    $spacing = (int)round($hole_h * 2.5);
    $hole_color = imagecolorallocate($canvas, 0, 0, 0);
    $edge_color = imagecolorallocate($canvas, 50, 50, 50);

    // Margin from strip edge
    $hole_x_left  = (int)round(($strip_w - $hole_w) / 2);
    $hole_x_right = $sq - $strip_w + $hole_x_left;

    $y = (int)round($spacing * 0.4);
    while ($y + $hole_h < $sq)
    {
        // Left hole
        imagefilledrectangle($canvas, $hole_x_left, $y, $hole_x_left + $hole_w - 1, $y + $hole_h - 1, $hole_color);
        imagerectangle($canvas, $hole_x_left, $y, $hole_x_left + $hole_w - 1, $y + $hole_h - 1, $edge_color);
        // Right hole
        imagefilledrectangle($canvas, $hole_x_right, $y, $hole_x_right + $hole_w - 1, $y + $hole_h - 1, $hole_color);
        imagerectangle($canvas, $hole_x_right, $y, $hole_x_right + $hole_w - 1, $y + $hole_h - 1, $edge_color);
        $y += $spacing;
    }

    // Thin frame lines around image area
    $frame = imagecolorallocate($canvas, 40, 40, 40);
    imagerectangle($canvas, $strip_w - 1, 0, $sq - $strip_w, $sq - 1, $frame);

    // Center the source image
    $dx = $strip_w;
    $dy = (int)round(($sq - $src_h) / 2);
    imagecopy($canvas, $src, $dx, $dy, 0, 0, $src_w, $src_h);
    imagedestroy($src);

    return $canvas;
}

/**
 * Draw a YouTube-style play button natively in GD.
 * Returns a truecolor GD image (transparent background) of size $size × $size,
 * ready to be composited with imagecopy() on an alphablending-enabled canvas.
 *
 * $size        : side length in pixels (the button is square)
 * $opacity_pct : 0 (invisible) → 100 (fully opaque)
 */
function companion_gd_play_button($size, $opacity_pct = 70)
{
    $size = max(16, $size);
    // GD alpha: 0 = fully opaque, 127 = fully transparent
    $gd_alpha = (int)round(127 * (1.0 - max(0, min(100, $opacity_pct)) / 100.0));

    $img = imagecreatetruecolor($size, $size);
    imagealphablending($img, false);
    imagesavealpha($img, true);

    // Fill with full transparency
    $clear = imagecolorallocatealpha($img, 0, 0, 0, 127);
    imagefilledrectangle($img, 0, 0, $size - 1, $size - 1, $clear);

    // --- Rounded rectangle background ---
    // Proportions matching the YouTube icon: W:H = 4:3, radius ~18% of height
    $bg_w    = (int)round($size * 0.90);
    $bg_h    = (int)round($bg_w * 0.75);
    $bg_x    = (int)round(($size - $bg_w) / 2);
    $bg_y    = (int)round(($size - $bg_h) / 2);
    $radius  = (int)round($bg_h * 0.18);
    $bg_col  = imagecolorallocatealpha($img, 80, 80, 80, $gd_alpha);

    imagealphablending($img, true);

    // Fill rounded rect: center + 4 edges + 4 corner arcs
    imagefilledrectangle($img, $bg_x + $radius, $bg_y,            $bg_x + $bg_w - $radius, $bg_y + $bg_h,            $bg_col);
    imagefilledrectangle($img, $bg_x,            $bg_y + $radius, $bg_x + $bg_w,            $bg_y + $bg_h - $radius, $bg_col);
    imagefilledarc($img, $bg_x + $radius,            $bg_y + $radius,            $radius * 2, $radius * 2, 180, 270, $bg_col, IMG_ARC_PIE);
    imagefilledarc($img, $bg_x + $bg_w - $radius,   $bg_y + $radius,            $radius * 2, $radius * 2, 270, 360, $bg_col, IMG_ARC_PIE);
    imagefilledarc($img, $bg_x + $radius,            $bg_y + $bg_h - $radius,   $radius * 2, $radius * 2,  90, 180, $bg_col, IMG_ARC_PIE);
    imagefilledarc($img, $bg_x + $bg_w - $radius,   $bg_y + $bg_h - $radius,   $radius * 2, $radius * 2,   0,  90, $bg_col, IMG_ARC_PIE);

    // --- Triangle (play arrow) ---
    // Centered in the rounded rect, slightly right-offset for optical balance
    $tri_h  = (int)round($bg_h * 0.48);
    $tri_w  = (int)round($tri_h * 0.87);  // equilateral-ish
    $tri_cx = (int)round($bg_x + $bg_w * 0.52);  // slight optical right shift
    $tri_cy = (int)round($bg_y + $bg_h / 2);

    $tri_col = imagecolorallocatealpha($img, 255, 255, 255, $gd_alpha);
    imagefilledpolygon($img, array(
        $tri_cx - (int)round($tri_w * 0.40), $tri_cy - (int)round($tri_h / 2),  // top-left
        $tri_cx - (int)round($tri_w * 0.40), $tri_cy + (int)round($tri_h / 2),  // bottom-left
        $tri_cx + (int)round($tri_w * 0.60), $tri_cy,                            // right (tip)
    ), 3, $tri_col);

    imagealphablending($img, false);
    return $img;
}

// =========================================================================
//  Helpers
// =========================================================================

/**
 * Check if local config file is writable (or parent dir is writable if file doesn't exist)
 */
function companion_is_local_config_writable()
{
    $config_path = PHPWG_ROOT_PATH . 'local/config/config.inc.php';
    if (file_exists($config_path))
    {
        return is_writable($config_path);
    }
    // File doesn't exist — check if directory is writable
    $dir = dirname($config_path);
    return is_dir($dir) && is_writable($dir);
}

/**
 * Detect a CLI tool: find its path and get version output
 */
function companion_detect_tool($name, $version_flag)
{
    $result = array('installed' => false);

    $path = companion_find_executable($name);
    if ($path === false)
    {
        return $result;
    }

    $result['installed'] = true;
    $result['path'] = $path;

    $output = array();
    @exec(escapeshellarg($path) . ' ' . $version_flag . ' 2>&1', $output);
    if (!empty($output))
    {
        $result['version'] = trim($output[0]);
    }

    return $result;
}

/**
 * Try to find an executable in PATH or common locations
 */
function companion_find_executable($name)
{
    // Try which/where
    $cmd = (PHP_OS_FAMILY === 'Windows') ? 'where' : 'which';
    $output = array();
    $return_var = -1;
    @exec($cmd . ' ' . escapeshellarg($name) . ' 2>&1', $output, $return_var);

    if ($return_var === 0 && !empty($output))
    {
        return trim($output[0]);
    }

    // Fallback: common paths
    $paths = array(
        '/usr/bin/',
        '/usr/local/bin/',
        '/opt/bin/',
        '/opt/local/bin/',
        '/snap/bin/',
    );

    foreach ($paths as $path)
    {
        if (file_exists($path . $name))
        {
            return $path . $name;
        }
    }

    return false;
}
