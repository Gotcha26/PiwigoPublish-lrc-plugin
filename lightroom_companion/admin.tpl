<script>
(function(){
  var t = "{$LRC_THEME}";
  function apply(){
    document.documentElement.setAttribute("data-lrc-theme", t);
  }
  if (document.body) { apply(); }
  else { document.addEventListener("DOMContentLoaded", apply); }
})();
</script>

<style>
/* === Lightroom Companion — variables thème === */
:root,
[data-lrc-theme="clear"] {
  --lrc-color-section-border : #ccc;
  --lrc-color-section-text   : #444;
  --lrc-color-label          : #555;
  --lrc-color-note           : #666;
  --lrc-color-pre-bg         : #f5f5f5;
  --lrc-color-pre-border     : #ddd;
  --lrc-status-bg-ok         : #edfaed;
  --lrc-status-bg-err        : #fdecea;
  --lrc-status-border-ok     : #2a9d2a;
  --lrc-status-border-err    : #c0392b;
}
[data-lrc-theme="dark"] {
  --lrc-color-section-border : #555;
  --lrc-color-section-text   : #ccc;
  --lrc-color-label          : #aaa;
  --lrc-color-note           : #888;
  --lrc-color-pre-bg         : #1e1e1e;
  --lrc-color-pre-border     : #444;
  --lrc-status-bg-ok         : #1a2e1a;
  --lrc-status-bg-err        : #2e1a1a;
  --lrc-status-border-ok     : #2a9d2a;
  --lrc-status-border-err    : #c0392b;
}

.lrc-wrap        { max-width: 820px; }
.lrc-section     { margin: 20px 0 6px; font-size: 1.05em; font-weight: bold;
                   border-bottom: 2px solid var(--lrc-color-section-border);
                   padding-bottom: 3px; color: var(--lrc-color-section-text); }
.lrc-table       { border-collapse: collapse; width: 100%; margin-bottom: 4px; }
.lrc-table td    { padding: 4px 6px; vertical-align: top; }
.lrc-label       { width: 230px; font-weight: bold; color: var(--lrc-color-label); white-space: nowrap; }
.lrc-ok          { color: #2a9d2a; font-weight: bold; }
.lrc-err         { color: #c0392b; font-weight: bold; }
.lrc-warn        { color: #e67e22; font-weight: bold; }
.lrc-note        { font-size: 0.87em; color: var(--lrc-color-note); font-style: italic;
                   padding: 2px 6px 6px 240px; }
.lrc-action      { margin: 14px 0 4px; }
.lrc-pre         { background: var(--lrc-color-pre-bg); border: 1px solid var(--lrc-color-pre-border);
                   padding: 8px 12px; font-family: monospace; font-size: 0.88em; white-space: pre-wrap; }

/* Status banner (onglet Video) */
.lrc-status-banner {
  display: flex; align-items: center; gap: 16px;
  padding: 14px 18px; border-radius: 4px; margin: 16px 0;
  border-left: 4px solid var(--lrc-status-border-ok);
  background: var(--lrc-status-bg-ok);
}
.lrc-status-banner.lrc-banner-err {
  border-color: var(--lrc-status-border-err);
  background: var(--lrc-status-bg-err);
}
.lrc-status-icon { font-size: 2em; line-height: 1; }
.lrc-status-text { flex: 1; }
.lrc-status-text strong { display: block; font-size: 1.1em; margin-bottom: 2px; }
.lrc-status-text small  { color: var(--lrc-color-note); }
</style>

<div class="lrc-wrap">

  <h2>Lightroom Companion <small style="font-size:0.55em; font-style:italic; font-weight:normal">v{$LRC_PLUGIN_VERSION}</small></h2>

  {* Tabsheet natif Piwigo *}
  {include file='tabsheet.tpl'}

  {* ---- Action result ---- *}
  {if $LRC_ACTION_STATUS eq 'ok' or $LRC_ACTION_STATUS eq 'already_configured'}
    <p class="lrc-ok" style="margin:10px 0">{$LRC_ACTION_MESSAGE}</p>
  {elseif $LRC_ACTION_STATUS}
    <p class="lrc-err" style="margin:10px 0">{$LRC_ACTION_MESSAGE}</p>
  {/if}

  {* ================================================================= *}
  {* TAB VIDEO                                                           *}
  {* ================================================================= *}
  {if $LRC_TAB eq 'video'}

    {* --- Statut global --- *}
    {if $LRC_VIDEO_READY and $LRC_VJS_ACTIVE}
      <div class="lrc-status-banner">
        <div class="lrc-status-icon">&#10003;</div>
        <div class="lrc-status-text">
          <strong class="lrc-ok">{'lrc_video_fully_active'|translate}</strong>
          <small>{'lrc_video_fully_active_sub'|translate}</small>
        </div>
      </div>
    {else}
      <div class="lrc-status-banner lrc-banner-err">
        <div class="lrc-status-icon">&#33;</div>
        <div class="lrc-status-text">
          <strong class="lrc-err">{'lrc_video_not_configured'|translate}</strong>
          <small>{'lrc_video_not_configured_sub'|translate}</small>
        </div>
      </div>
    {/if}

    {* --- Upload Piwigo --- *}
    <div class="lrc-section">{'lrc_section_video_upload'|translate}</div>
    <table class="lrc-table">
      <tr>
        <td class="lrc-label">{'lrc_upload_status'|translate}</td>
        <td>
          {if $LRC_VIDEO_READY}
            <span class="lrc-ok">{'lrc_ready'|translate}</span>
          {else}
            <span class="lrc-err">{'lrc_not_configured'|translate}</span>
          {/if}
        </td>
      </tr>
      <tr>
        <td class="lrc-label">{'lrc_all_file_types'|translate}</td>
        <td>
          {if $LRC_UPLOAD_ALL}
            <span class="lrc-ok">{'lrc_enabled'|translate}</span>
          {else}
            <span class="lrc-err">{'lrc_disabled'|translate}</span>
          {/if}
        </td>
      </tr>
      <tr>
        <td class="lrc-label">{'lrc_video_extensions'|translate}</td>
        <td>
          {if $LRC_VIDEO_EXTS}
            {$LRC_VIDEO_EXTS}
          {else}
            <span class="lrc-err">{'lrc_none_configured'|translate}</span>
          {/if}
        </td>
      </tr>
    </table>

    {if $LRC_CFG_WRITABLE}
      <div class="lrc-action">
        {if not $LRC_VIDEO_READY}
          <form method="post" action="{$LRC_ADMIN_URL}&tab=video">
            <input type="hidden" name="action" value="enable_video_support">
            <input type="hidden" name="pwg_token" value="{$PWG_TOKEN}">
            <input type="submit" class="submit" value="{'lrc_enable_video'|translate}">
          </form>
          <p class="lrc-note">{'lrc_enable_video_note'|translate}</p>
        {elseif $LRC_COMPANION_BLOCK}
          <form method="post" action="{$LRC_ADMIN_URL}&tab=video">
            <input type="hidden" name="action" value="disable_video_support">
            <input type="hidden" name="pwg_token" value="{$PWG_TOKEN}">
            <input type="submit" class="submit" value="{'lrc_disable_video'|translate}" style="background:#c0392b">
          </form>
          <p class="lrc-note">{'lrc_disable_video_note'|translate}</p>
        {/if}
      </div>
    {elseif not $LRC_VIDEO_READY}
      <p class="lrc-err" style="margin-top:10px">{'lrc_config_not_writable'|translate}</p>
      <div class="lrc-pre">$conf['upload_form_all_types'] = true;
$conf['file_ext'] = array_merge($conf['picture_ext'], array('mp4', 'm4v', 'ogg', 'ogv', 'webm'));</div>
    {/if}

    {* --- VideoJS plugin --- *}
    <div class="lrc-section">{'lrc_section_videojs'|translate}</div>
    <table class="lrc-table">
      {if $LRC_VJS_INSTALLED}
        <tr>
          <td class="lrc-label">{'lrc_plugin'|translate}</td>
          <td>{$LRC_VJS_NAME}</td>
        </tr>
        <tr>
          <td class="lrc-label">{'lrc_status'|translate}</td>
          <td>
            {if $LRC_VJS_ACTIVE}
              <span class="lrc-ok">{'lrc_active'|translate}</span>
            {else}
              <span class="lrc-warn">{'lrc_installed_inactive'|translate}</span>
            {/if}
          </td>
        </tr>
      {else}
        <tr>
          <td class="lrc-label">VideoJS</td>
          <td><span class="lrc-err">{'lrc_not_installed'|translate}</span></td>
        </tr>
      {/if}
    </table>
    {if not $LRC_VJS_INSTALLED}
      <p class="lrc-note">{'lrc_videojs_install_note'|translate}</p>
    {elseif not $LRC_VJS_ACTIVE}
      <p class="lrc-note">{'lrc_videojs_activate_note'|translate}</p>
    {/if}

  {/if}{* end tab video *}

  {* ================================================================= *}
  {* TAB SERVER                                                          *}
  {* ================================================================= *}
  {if $LRC_TAB eq 'server'}

    {* --- CLI Tools --- *}
    <div class="lrc-section">{'lrc_section_media_tools'|translate}</div>
    <table class="lrc-table">
      <tr>
        <td class="lrc-label">FFmpeg</td>
        <td class="{if $LRC_FFMPEG_OK}lrc-ok{/if}">{$LRC_FFMPEG_VER}</td>
      </tr>
      <tr>
        <td class="lrc-label">FFprobe</td>
        <td class="{if $LRC_FFPROBE_OK}lrc-ok{/if}">{$LRC_FFPROBE_VER}</td>
      </tr>
      <tr>
        <td class="lrc-label">ExifTool</td>
        <td class="{if $LRC_EXIFTOOL_OK}lrc-ok{/if}">{$LRC_EXIFTOOL_VER}</td>
      </tr>
      <tr>
        <td class="lrc-label">MediaInfo</td>
        <td class="{if $LRC_MEDIAINFO_OK}lrc-ok{/if}">{$LRC_MEDIAINFO_VER}</td>
      </tr>
    </table>
    {if $LRC_FFMPEG_NO_TPL}
      <p class="lrc-note">{'lrc_ffmpeg_no_note'|translate}</p>
    {/if}

    {* --- Server & PHP --- *}
    <div class="lrc-section">{'lrc_section_server_php'|translate}</div>
    <table class="lrc-table">
      <tr><td class="lrc-label">{'lrc_os'|translate}</td><td>{$LRC_OS}</td></tr>
      <tr><td class="lrc-label">{'lrc_web_server'|translate}</td><td>{$LRC_WEBSERVER}</td></tr>
      <tr><td class="lrc-label">{'lrc_php_version'|translate}</td><td>{$LRC_PHP_VERSION}</td></tr>
      <tr><td class="lrc-label">upload_max_filesize</td><td>{$LRC_PHP_UPLOAD}</td></tr>
      <tr><td class="lrc-label">post_max_size</td><td>{$LRC_PHP_POST}</td></tr>
      <tr><td class="lrc-label">memory_limit</td><td>{$LRC_PHP_MEM}</td></tr>
      <tr><td class="lrc-label">max_execution_time</td><td>{$LRC_PHP_MAXTIME}s</td></tr>
      <tr>
        <td class="lrc-label">{'lrc_exec_available'|translate}</td>
        <td>
          {if $LRC_PHP_EXEC}
            <span class="lrc-ok">{'lrc_yes'|translate}</span>
          {else}
            <span class="lrc-err">{'lrc_no'|translate}</span>
          {/if}
        </td>
      </tr>
    </table>
    {if $LRC_PHP_EXEC_NOTE}
      <p class="lrc-note">{$LRC_PHP_EXEC_NOTE}</p>
    {/if}

    {* --- Graphics --- *}
    <div class="lrc-section">{'lrc_section_graphics'|translate}</div>
    <table class="lrc-table">
      <tr>
        <td class="lrc-label">GD</td>
        <td>
          {if $LRC_GD}
            <span class="lrc-ok">{$LRC_GD}</span>
          {else}
            <span class="lrc-err">{'lrc_not_available'|translate}</span>
          {/if}
        </td>
      </tr>
      <tr>
        <td class="lrc-label">ImageMagick</td>
        <td>
          {if $LRC_IMAGICK}
            <span class="lrc-ok">{$LRC_IMAGICK}</span>
          {else}
            {'lrc_not_available'|translate}
          {/if}
        </td>
      </tr>
    </table>

    {* --- Piwigo --- *}
    <div class="lrc-section">{'lrc_section_piwigo'|translate}</div>
    <table class="lrc-table">
      <tr><td class="lrc-label">{'lrc_version'|translate}</td><td>{$LRC_PIWIGO_VER}</td></tr>
      <tr>
        <td class="lrc-label">{'lrc_guest_theme'|translate}</td>
        <td>
          <code>{$LRC_PUBLIC_THEME}</code>
          {if $LRC_PARENT_THEME neq $LRC_PUBLIC_THEME}
            <span class="lrc-note" style="margin-left:8px">&#8627; {'lrc_parent'|translate}: <code>{$LRC_PARENT_THEME}</code></span>
          {/if}
        </td>
      </tr>
      <tr>
        <td class="lrc-label">{'lrc_config_writable'|translate}</td>
        <td>
          {if $LRC_CFG_WRITABLE}
            <span class="lrc-ok">{'lrc_yes'|translate}</span>
          {else}
            <span class="lrc-err">{'lrc_no'|translate}</span>
          {/if}
        </td>
      </tr>
    </table>

  {/if}{* end tab server *}

  {* ================================================================= *}
  {* TAB SETTINGS                                                        *}
  {* ================================================================= *}
  {if $LRC_TAB eq 'settings'}

    {if not $LRC_HAS_GD}
      <div class="lrc-status-banner lrc-banner-err">
        <div class="lrc-status-icon">&#33;</div>
        <div class="lrc-status-text">
          <strong class="lrc-err">{'lrc_gd_not_available'|translate}</strong>
          <small>{'lrc_gd_not_available_sub'|translate}</small>
        </div>
      </div>
    {/if}

    <form method="post" action="{$LRC_ADMIN_URL}&tab=settings">
      <input type="hidden" name="action" value="save_settings">
      <input type="hidden" name="pwg_token" value="{$PWG_TOKEN}">

      {* --- Thumbnail size --- *}
      <div class="lrc-section">{'lrc_section_thumbnail'|translate}</div>
      <table class="lrc-table">
        <tr>
          <td class="lrc-label">{'lrc_max_size'|translate}</td>
          <td>
            <input type="number" name="thumb_max_size" value="{$LRC_CFG.thumb_max_size}"
                   min="50" max="1280" style="width:80px"> px
            <span style="color:var(--lrc-color-note); font-size:0.87em; margin-left:8px">({'lrc_longest_side'|translate})</span>
          </td>
        </tr>
        <tr>
          <td class="lrc-label">{'lrc_no_upscale'|translate}</td>
          <td>
            <label>
              <input type="checkbox" name="thumb_no_upscale" value="1"
                     {if $LRC_CFG.thumb_no_upscale}checked{/if}>
              {'lrc_no_enlarge'|translate}
            </label>
          </td>
        </tr>
      </table>

      {* --- Film strip --- *}
      <div class="lrc-section">{'lrc_section_filmstrip'|translate}</div>
      <table class="lrc-table">
        <tr>
          <td class="lrc-label">{'lrc_filmstrip_label'|translate}</td>
          <td>
            <label>
              <input type="checkbox" name="film_strip" value="1"
                     {if $LRC_CFG.film_strip}checked{/if}>
              {'lrc_filmstrip_option'|translate}
            </label>
          </td>
        </tr>
      </table>
      <p class="lrc-note">{'lrc_filmstrip_note'|translate}</p>

      {* --- Overlays --- *}
      <div class="lrc-section">{'lrc_section_overlays'|translate}</div>
      <table class="lrc-table">
        <tr>
          <td class="lrc-label">{'lrc_video_icon'|translate}</td>
          <td>
            <label>
              <input type="checkbox" name="overlay_video_icon" value="1"
                     {if $LRC_CFG.overlay_video_icon}checked{/if}
                     {if not $LRC_HAS_VIDEO_ICON}disabled{/if}>
              {'lrc_video_icon_option'|translate}
            </label>
            {if not $LRC_HAS_VIDEO_ICON}
              <span class="lrc-warn" style="font-size:0.87em; margin-left:8px">
                ({'lrc_missing_asset'|translate}: <code>assets/video-icon.png</code>)
              </span>
            {/if}
          </td>
        </tr>
        <tr>
          <td class="lrc-label">{'lrc_icon_position'|translate}</td>
          <td>
            <label>
              <input type="radio" name="overlay_video_pos" value="bottom-right"
                     {if $LRC_CFG.overlay_video_pos eq 'bottom-right'}checked{/if}>
              {'lrc_bottom_right'|translate}
            </label>
            &nbsp;&nbsp;
            <label>
              <input type="radio" name="overlay_video_pos" value="bottom-left"
                     {if $LRC_CFG.overlay_video_pos eq 'bottom-left'}checked{/if}>
              {'lrc_bottom_left'|translate}
            </label>
          </td>
        </tr>
        <tr>
          <td class="lrc-label">{'lrc_play_button'|translate}</td>
          <td>
            <label>
              <input type="checkbox" name="overlay_play" value="1"
                     {if $LRC_CFG.overlay_play}checked{/if}>
              {'lrc_play_button_option'|translate}
            </label>
            <span class="lrc-note" style="margin-left:8px; font-size:0.87em">{'lrc_play_native_note'|translate}</span>
          </td>
        </tr>
        <tr>
          <td class="lrc-label">{'lrc_play_size'|translate}</td>
          <td>
            <input type="number" name="overlay_play_size" min="5" max="50"
                   value="{$LRC_CFG.overlay_play_size|default:20}" style="width:60px"> %
            <span class="lrc-note" style="margin-left:6px">{'lrc_play_size_note'|translate}</span>
          </td>
        </tr>
        <tr>
          <td class="lrc-label">{'lrc_play_opacity'|translate}</td>
          <td>
            <input type="number" name="overlay_play_opacity" min="10" max="100"
                   value="{$LRC_CFG.overlay_play_opacity|default:100}" style="width:60px"> %
            <span class="lrc-note" style="margin-left:6px">{'lrc_play_opacity_note'|translate}</span>
          </td>
        </tr>
      </table>
      <p class="lrc-note">{'lrc_overlay_asset_note'|translate}</p>

      <div class="lrc-action">
        <input type="submit" class="submit" value="{'lrc_save_settings'|translate}">
      </div>
    </form>

  {/if}{* end tab settings *}

</div>
