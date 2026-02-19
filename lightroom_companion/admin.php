<?php
defined('PHPWG_ROOT_PATH') or die('Hacking attempt!');

include_once(PHPWG_ROOT_PATH . 'admin/include/tabsheet.class.php');

global $template, $conf, $page;

// =========================================================================
//  Tabs
// =========================================================================
$page['tab'] = isset($_GET['tab']) ? $_GET['tab'] : 'video';

$tabsheet = new tabsheet();
$tabsheet->add('video',    'Video',    get_admin_plugin_menu_link(dirname(__FILE__).'/admin.php') . '&tab=video');
$tabsheet->add('server',   'Server',   get_admin_plugin_menu_link(dirname(__FILE__).'/admin.php') . '&tab=server');
$tabsheet->add('settings', 'Settings', get_admin_plugin_menu_link(dirname(__FILE__).'/admin.php') . '&tab=settings');
$tabsheet->select($page['tab']);
$tabsheet->assign();

// =========================================================================
//  Handle POST action: Enable Video Support
// =========================================================================
$action_status  = null;
$action_message = null;

if (isset($_POST['action']) && $_POST['action'] === 'enable_video_support')
{
    check_pwg_token();
    $dummy_service = null;
    companion_enable_video_support(array(), $dummy_service);
    redirect(get_admin_plugin_menu_link(dirname(__FILE__).'/admin.php') . '&tab=video');
}

if (isset($_POST['action']) && $_POST['action'] === 'disable_video_support')
{
    check_pwg_token();
    $dummy_service = null;
    companion_disable_video_support(array(), $dummy_service);
    redirect(get_admin_plugin_menu_link(dirname(__FILE__).'/admin.php') . '&tab=video');
}

if (isset($_POST['action']) && $_POST['action'] === 'save_settings')
{
    check_pwg_token();

    $new_config = companion_get_all_config();

    $max_size = (int)($_POST['thumb_max_size'] ?? 350);
    $new_config['thumb_max_size']     = max(50, min(1280, $max_size));
    $new_config['thumb_no_upscale']   = isset($_POST['thumb_no_upscale']);
    $new_config['film_strip']         = isset($_POST['film_strip']);
    $new_config['overlay_video_icon'] = isset($_POST['overlay_video_icon']);
    $new_config['overlay_video_pos']  = in_array(($_POST['overlay_video_pos'] ?? ''), array('bottom-right', 'bottom-left'))
        ? $_POST['overlay_video_pos']
        : 'bottom-right';
    $new_config['overlay_play']         = isset($_POST['overlay_play']);
    $play_size = (int)($_POST['overlay_play_size'] ?? 20);
    $new_config['overlay_play_size']    = max(5, min(50, $play_size));
    $play_opacity = (int)($_POST['overlay_play_opacity'] ?? 70);
    $new_config['overlay_play_opacity'] = max(10, min(100, $play_opacity));

    conf_update_param('companion_config', json_encode($new_config));
    $conf['companion_config'] = json_encode($new_config);

    $action_status  = 'ok';
    $action_message = 'Settings saved.';
}

// =========================================================================
//  Gather server information
// =========================================================================

// PHP
$disabled_functions = array_map('trim', explode(',', ini_get('disable_functions')));
$exec_available = function_exists('exec') && !in_array('exec', $disabled_functions);

$php = array(
    'version'             => PHP_VERSION,
    'memory_limit'        => ini_get('memory_limit'),
    'upload_max_filesize' => ini_get('upload_max_filesize'),
    'post_max_size'       => ini_get('post_max_size'),
    'max_execution_time'  => ini_get('max_execution_time'),
    'exec_available'      => $exec_available,
);

// Graphics
$gfx_gd      = false;
$gfx_imagick = false;
if (function_exists('gd_info'))
{
    $gd = gd_info();
    $gfx_gd = isset($gd['GD Version']) ? $gd['GD Version'] : 'unknown';
}
if (extension_loaded('imagick'))
{
    try {
        $ver = Imagick::getVersion();
        $gfx_imagick = isset($ver['versionString']) ? $ver['versionString'] : 'unknown';
    } catch (Exception $e) {
        $gfx_imagick = 'error: ' . $e->getMessage();
    }
}

// CLI tools
if ($exec_available)
{
    $ffmpeg    = companion_detect_tool('ffmpeg',    '-version');
    $ffprobe   = companion_detect_tool('ffprobe',   '-version');
    $exiftool  = companion_detect_tool('exiftool',  '-ver');
    $mediainfo = companion_detect_tool('mediainfo', '--Version');
}
else
{
    $notice    = 'exec() is disabled — CLI tools cannot be detected';
    $ffmpeg    = array('installed' => false, 'notice' => $notice);
    $ffprobe   = array('installed' => false, 'notice' => $notice);
    $exiftool  = array('installed' => false, 'notice' => $notice);
    $mediainfo = array('installed' => false, 'notice' => $notice);
}

// Piwigo config
$upload_all       = isset($conf['upload_form_all_types']) ? (bool)$conf['upload_form_all_types'] : false;
$file_ext         = isset($conf['file_ext']) ? $conf['file_ext'] : array();
$video_exts_all   = array('mp4', 'm4v', 'ogg', 'ogv', 'webm', 'webmv', 'mpg', 'mpeg', 'mov', 'avi');
$found_video_exts = array_values(array_intersect($file_ext, $video_exts_all));
$video_ready      = $upload_all && !empty($found_video_exts);
$config_writable  = companion_is_local_config_writable();

// VideoJS detection
// $plugins global: keys are plugin IDs, values contain plugin metadata.
// Active plugins only appear in $plugins; installed-but-inactive ones require a DB query.
global $plugins;
$videojs_installed = false;
$videojs_active    = false;
$videojs_name      = '';

// Helper: test if a string contains "videojs" or "video_js"
function companion_is_videojs($str)
{
    $s = strtolower($str);
    return strpos($s, 'videojs') !== false || strpos($s, 'video_js') !== false;
}

// 1. Search active plugins ($plugins key = plugin id)
if (!empty($plugins))
{
    foreach ($plugins as $pid => $pdata)
    {
        $name = isset($pdata['name']) ? $pdata['name'] : $pid;
        if (companion_is_videojs($pid) || companion_is_videojs($name))
        {
            $videojs_installed = true;
            $videojs_active    = true;   // present in $plugins → active
            $videojs_name      = $name;
            break;
        }
    }
}

// 2. If not found among active plugins, check installed-but-inactive via DB.
// PLUGINS_TABLE only has columns: id, state, version — no name column.
if (!$videojs_installed)
{
    $query = '
SELECT id, state
FROM ' . PLUGINS_TABLE . '
;';
    $result_db = pwg_query($query);
    while ($row = pwg_db_fetch_assoc($result_db))
    {
        if (companion_is_videojs($row['id']))
        {
            $videojs_installed = true;
            $videojs_active    = ($row['state'] === 'active');
            $videojs_name      = $row['id'];   // no name in DB, use id
            break;
        }
    }
}

// =========================================================================
//  Theme detection (clear / dark) — same logic as centralAdmin
// =========================================================================
$lrc_theme = 'clear';
if (function_exists('userprefs_get_param'))
{
    $lrc_theme = (userprefs_get_param('admin_theme', 'clear') === 'roma') ? 'dark' : 'clear';
}

// =========================================================================
//  Assign to template
// =========================================================================
// Read plugin version from main file header
$lrc_plugin_version = '?';
$main_file = dirname(__FILE__) . '/main.inc.php';
if (file_exists($main_file))
{
    $header = file_get_contents($main_file, false, null, 0, 512);
    if (preg_match('/Version:\s*([^\r\n]+)/', $header, $m))
        $lrc_plugin_version = trim($m[1]);
}

$template->assign(array(
    'LRC_ADMIN_URL'        => get_admin_plugin_menu_link(dirname(__FILE__).'/admin.php'),
    'PWG_TOKEN'            => get_pwg_token(),
    'LRC_TAB'              => $page['tab'],
    'LRC_PLUGIN_VERSION'   => $lrc_plugin_version,

    // Action result
    'LRC_ACTION_STATUS'  => $action_status,
    'LRC_ACTION_MESSAGE' => $action_message,

    // PHP
    'LRC_PHP_VERSION'    => $php['version'],
    'LRC_PHP_MEM'        => $php['memory_limit'],
    'LRC_PHP_UPLOAD'     => $php['upload_max_filesize'],
    'LRC_PHP_POST'       => $php['post_max_size'],
    'LRC_PHP_MAXTIME'    => $php['max_execution_time'],
    'LRC_PHP_EXEC'       => $exec_available,
    'LRC_PHP_EXEC_NOTE'  => $exec_available ? '' : 'exec() is disabled — contact your hosting provider',

    // Graphics
    'LRC_GD'             => $gfx_gd,
    'LRC_IMAGICK'        => $gfx_imagick,

    // CLI tools
    'LRC_FFMPEG_OK'      => $ffmpeg['installed'],
    'LRC_FFMPEG_VER'     => $ffmpeg['installed'] ? ($ffmpeg['version'] ?? 'Installed') : ($ffmpeg['notice'] ?? 'Not found'),
    'LRC_FFPROBE_OK'     => $ffprobe['installed'],
    'LRC_FFPROBE_VER'    => $ffprobe['installed'] ? ($ffprobe['version'] ?? 'Available') : ($ffprobe['notice'] ?? 'Not found'),
    'LRC_EXIFTOOL_OK'    => $exiftool['installed'],
    'LRC_EXIFTOOL_VER'   => $exiftool['installed'] ? ($exiftool['version'] ?? 'Installed') : ($exiftool['notice'] ?? 'Not found'),
    'LRC_MEDIAINFO_OK'   => $mediainfo['installed'],
    'LRC_MEDIAINFO_VER'  => $mediainfo['installed'] ? ($mediainfo['version'] ?? 'Installed') : ($mediainfo['notice'] ?? 'Not found'),
    'LRC_FFMPEG_NO_TPL'  => (!$ffmpeg['installed'] && !isset($ffmpeg['notice'])),

    // Piwigo
    'LRC_PIWIGO_VER'     => PHPWG_VERSION,
    'LRC_PUBLIC_THEME'   => companion_get_public_theme(),
    'LRC_PARENT_THEME'   => companion_get_parent_theme(),
    'LRC_UPLOAD_ALL'     => $upload_all,
    'LRC_VIDEO_EXTS'     => implode(', ', $found_video_exts),
    'LRC_VIDEO_READY'    => $video_ready,
    'LRC_CFG_WRITABLE'   => $config_writable,

    // VideoJS
    'LRC_VJS_INSTALLED'  => $videojs_installed,
    'LRC_VJS_ACTIVE'     => $videojs_active,
    'LRC_VJS_NAME'       => $videojs_name,

    // Theme
    'LRC_THEME'          => $lrc_theme,

    // OS
    'LRC_OS'             => PHP_OS,
    'LRC_WEBSERVER'      => $_SERVER['SERVER_SOFTWARE'] ?? 'unknown',

    // Settings
    'LRC_CFG'            => companion_get_all_config(),
    'LRC_HAS_GD'              => function_exists('imagecreatetruecolor'),
    'LRC_HAS_VIDEO_ICON'      => file_exists(dirname(__FILE__) . '/assets/video-icon.png'),
    'LRC_COMPANION_BLOCK'     => companion_has_video_block(),
));

// Render template
$template->set_filenames(array(
    'plugin_admin_content' => dirname(__FILE__) . '/admin.tpl',
));
$template->assign_var_from_handle('ADMIN_CONTENT', 'plugin_admin_content');
