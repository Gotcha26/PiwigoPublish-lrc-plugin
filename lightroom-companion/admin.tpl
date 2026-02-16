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

  <h2>Lightroom Companion</h2>

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
          <strong class="lrc-ok">Video support is fully active</strong>
          <small>Upload enabled &amp; VideoJS plugin active — videos can be published from Lightroom.</small>
        </div>
      </div>
    {else}
      <div class="lrc-status-banner lrc-banner-err">
        <div class="lrc-status-icon">&#33;</div>
        <div class="lrc-status-text">
          <strong class="lrc-err">Video support is not fully configured</strong>
          <small>Check the items below and fix each one.</small>
        </div>
      </div>
    {/if}

    {* --- Upload Piwigo --- *}
    <div class="lrc-section">Video Upload (Piwigo)</div>
    <table class="lrc-table">
      <tr>
        <td class="lrc-label">Upload status</td>
        <td>
          {if $LRC_VIDEO_READY}
            <span class="lrc-ok">Ready</span>
          {else}
            <span class="lrc-err">Not configured</span>
          {/if}
        </td>
      </tr>
      <tr>
        <td class="lrc-label">All file types</td>
        <td>
          {if $LRC_UPLOAD_ALL}
            <span class="lrc-ok">Enabled</span>
          {else}
            <span class="lrc-err">Disabled</span>
          {/if}
        </td>
      </tr>
      <tr>
        <td class="lrc-label">Video extensions</td>
        <td>
          {if $LRC_VIDEO_EXTS}
            {$LRC_VIDEO_EXTS}
          {else}
            <span class="lrc-err">None configured</span>
          {/if}
        </td>
      </tr>
    </table>

    {if not $LRC_VIDEO_READY}
      {if $LRC_CFG_WRITABLE}
        <div class="lrc-action">
          <form method="post" action="{$LRC_ADMIN_URL}&tab=video">
            <input type="hidden" name="action" value="enable_video_support">
            <input type="hidden" name="pwg_token" value="{$PWG_TOKEN}">
            <input type="submit" class="submit" value="Enable Video Support">
          </form>
          <p class="lrc-note">Adds <code>upload_form_all_types = true</code> and video extensions (mp4, m4v, ogg, ogv, webm) to <code>local/config/config.inc.php</code>.</p>
        </div>
      {else}
        <p class="lrc-err" style="margin-top:10px">Config file is not writable. Add manually to <code>local/config/config.inc.php</code>:</p>
        <div class="lrc-pre">$conf['upload_form_all_types'] = true;
$conf['file_ext'] = array_merge($conf['picture_ext'], array('mp4', 'm4v', 'ogg', 'ogv', 'webm'));</div>
      {/if}
    {/if}

    {* --- VideoJS plugin --- *}
    <div class="lrc-section">VideoJS Plugin</div>
    <table class="lrc-table">
      {if $LRC_VJS_INSTALLED}
        <tr>
          <td class="lrc-label">Plugin</td>
          <td>{$LRC_VJS_NAME}</td>
        </tr>
        <tr>
          <td class="lrc-label">Status</td>
          <td>
            {if $LRC_VJS_ACTIVE}
              <span class="lrc-ok">Active</span>
            {else}
              <span class="lrc-warn">Installed but INACTIVE</span>
            {/if}
          </td>
        </tr>
      {else}
        <tr>
          <td class="lrc-label">VideoJS</td>
          <td><span class="lrc-err">Not installed</span></td>
        </tr>
      {/if}
    </table>
    {if not $LRC_VJS_INSTALLED}
      <p class="lrc-note">Install and activate the VideoJS plugin from Piwigo administration for in-gallery video playback.</p>
    {elseif not $LRC_VJS_ACTIVE}
      <p class="lrc-note">Activate VideoJS in Piwigo administration (Plugins menu) for video playback to work.</p>
    {/if}

  {/if}{* end tab video *}

  {* ================================================================= *}
  {* TAB SERVER                                                          *}
  {* ================================================================= *}
  {if $LRC_TAB eq 'server'}

    {* --- CLI Tools --- *}
    <div class="lrc-section">Video &amp; Media Tools</div>
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
      <p class="lrc-note">Without FFmpeg, videos will upload but Piwigo will not generate a custom thumbnail for them.</p>
    {/if}

    {* --- Server & PHP --- *}
    <div class="lrc-section">Server &amp; PHP</div>
    <table class="lrc-table">
      <tr><td class="lrc-label">OS</td><td>{$LRC_OS}</td></tr>
      <tr><td class="lrc-label">Web Server</td><td>{$LRC_WEBSERVER}</td></tr>
      <tr><td class="lrc-label">PHP Version</td><td>{$LRC_PHP_VERSION}</td></tr>
      <tr><td class="lrc-label">upload_max_filesize</td><td>{$LRC_PHP_UPLOAD}</td></tr>
      <tr><td class="lrc-label">post_max_size</td><td>{$LRC_PHP_POST}</td></tr>
      <tr><td class="lrc-label">memory_limit</td><td>{$LRC_PHP_MEM}</td></tr>
      <tr><td class="lrc-label">max_execution_time</td><td>{$LRC_PHP_MAXTIME}s</td></tr>
      <tr>
        <td class="lrc-label">exec() available</td>
        <td>
          {if $LRC_PHP_EXEC}
            <span class="lrc-ok">Yes</span>
          {else}
            <span class="lrc-err">No</span>
          {/if}
        </td>
      </tr>
    </table>
    {if $LRC_PHP_EXEC_NOTE}
      <p class="lrc-note">{$LRC_PHP_EXEC_NOTE}</p>
    {/if}

    {* --- Graphics --- *}
    <div class="lrc-section">Graphics Libraries</div>
    <table class="lrc-table">
      <tr>
        <td class="lrc-label">GD</td>
        <td>
          {if $LRC_GD}
            <span class="lrc-ok">{$LRC_GD}</span>
          {else}
            <span class="lrc-err">Not available</span>
          {/if}
        </td>
      </tr>
      <tr>
        <td class="lrc-label">ImageMagick</td>
        <td>
          {if $LRC_IMAGICK}
            <span class="lrc-ok">{$LRC_IMAGICK}</span>
          {else}
            Not available
          {/if}
        </td>
      </tr>
    </table>

    {* --- Piwigo --- *}
    <div class="lrc-section">Piwigo Gallery</div>
    <table class="lrc-table">
      <tr><td class="lrc-label">Version</td><td>{$LRC_PIWIGO_VER}</td></tr>
      <tr>
        <td class="lrc-label">Config file writable</td>
        <td>
          {if $LRC_CFG_WRITABLE}
            <span class="lrc-ok">Yes</span>
          {else}
            <span class="lrc-err">No</span>
          {/if}
        </td>
      </tr>
    </table>

  {/if}{* end tab server *}

</div>
