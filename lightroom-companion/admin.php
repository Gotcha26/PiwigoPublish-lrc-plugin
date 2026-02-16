<?php
defined('PHPWG_ROOT_PATH') or die('Hacking attempt!');

include_once(PHPWG_ROOT_PATH . 'admin/include/tabsheet.class.php');

global $template, $conf, $page;

// =========================================================================
//  Tabs
// =========================================================================
$page['tab'] = isset($_GET['tab']) ? $_GET['tab'] : 'video';

$tabsheet = new tabsheet();
$tabsheet->add('video',  'Video',   get_admin_plugin_menu_link(dirname(__FILE__).'/admin.php') . '&tab=video');
$tabsheet->add('server', 'Server',  get_admin_plugin_menu_link(dirname(__FILE__).'/admin.php') . '&tab=server');
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
    $result = companion_enable_video_support(array(), $dummy_service);
    $action_status  = $result['status'];
    $action_message = $result['message'];
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
$template->assign(array(
    'LRC_ADMIN_URL'      => get_admin_plugin_menu_link(dirname(__FILE__).'/admin.php'),
    'PWG_TOKEN'          => get_pwg_token(),
    'LRC_TAB'            => $page['tab'],

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
));

// Render template
$template->set_filenames(array(
    'plugin_admin_content' => dirname(__FILE__) . '/admin.tpl',
));
$template->assign_var_from_handle('ADMIN_CONTENT', 'plugin_admin_content');
