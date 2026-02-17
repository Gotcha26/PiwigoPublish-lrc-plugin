<?php
/*
Plugin Name: Lightroom Companion
Version: 1.2.0
Description: Companion plugin for the PiwigoPublish Lightroom plugin. Exposes server diagnostics, provides automatic video upload configuration, and includes an administration page.
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

    // Piwigo representative: same filename as image but with new extension
    $image_basename = pathinfo($row['path'], PATHINFO_FILENAME);
    $representative_filename = $image_basename . '.' . $uploaded_ext;
    $representative_path = $image_dir . '/' . $representative_filename;

    if (!move_uploaded_file($_FILES['file']['tmp_name'], $representative_path))
    {
        return new PwgError(500, 'Failed to move uploaded poster to ' . $representative_path);
    }

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
