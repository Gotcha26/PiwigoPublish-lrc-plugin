# Auto-Update System for PiwigoPublish Plugin

By Gotcha26 - contact@julien-moreau.fr

## Overview

The auto-update system allows the PiwigoPublish Lightroom plugin to check for new versions via the GitHub Releases API and notify users when updates are available.

## Features

- **Automatic check on startup**: Silent check when Lightroom loads (once per day)
- **Manual check**: Button in Plugin Manager to check on demand
- **Multi-format versioning**: Supports both date-based and SemVer formats
- **Cross-format comparison**: Can compare versions even when switching versioning schemes
- **User-friendly notifications**: Dialog with changelog and download link

## Version Format Support

| Format | Example | Use Case |
|--------|---------|----------|
| Date-based | `20260121.3` or `v20260121.3` | Current format, revision incremented daily |
| SemVer | `1.2.3` or `v1.2.3` | Industry standard, for future migration |

The system automatically detects which format is used and applies the appropriate comparison logic.

### Cross-Format Comparison

When the local and remote versions use different formats, the system falls back to comparing the **GitHub release publish date** (`published_at` metadata) against the **build date** embedded in the local version.

This ensures seamless updates even if the versioning scheme changes in the future.

## Configuration

In `UpdateChecker.lua`, the following constants can be adjusted:

```lua
UpdateChecker.GITHUB_OWNER = "Piwigo"           -- GitHub organization/user
UpdateChecker.GITHUB_REPO = "PiwigoPublish-lrc-plugin"  -- Repository name
UpdateChecker.CHECK_INTERVAL_DAYS = 1           -- Days between automatic checks
```

## User Interface

### Plugin Manager Section

A new "Plugin Updates" section appears in **File > Plug-in Manager > Piwigo Publisher**:

- Current version display
- Update status indicator
- "Check for Updates" button
- "Visit GitHub Repository" button

### Update Notification Dialog

When an update is available, users see:

- Current vs. new version comparison
- Changelog excerpt (first 500 characters)
- "Download" button → opens GitHub release page
- "Later" button → dismisses until next check

## Creating a New Release

1. Update `VERSION` in `Info.lua`:
   ```lua
   VERSION = { major=20260122, minor=1, revision=0 },
   ```

2. Commit and push changes

3. Create a GitHub Release:
   - **Tag**: `v20260122.1` (or `v1.0.0` for SemVer)
   - **Title**: Version number or descriptive title
   - **Description**: Changelog in Markdown format

4. The plugin will automatically detect the new release

## Technical Details

### API Endpoint

```
GET https://api.github.com/repos/{owner}/{repo}/releases/latest
```

### Response Fields Used

| Field | Purpose |
|-------|---------|
| `tag_name` | Version identifier |
| `published_at` | Release date (ISO 8601) for cross-format comparison |
| `body` | Changelog content (Markdown) |
| `html_url` | Download page URL |

### Storage (LrPrefs)

| Key | Purpose |
|-----|---------|
| `lastUpdateCheck` | Timestamp of last check |
| `latestVersion` | Cached latest version string |
| `latestVersionUrl` | Cached download URL |
| `pluginBuildDate` | Build date for SemVer installations |

## Functions Reference

| Function | Description |
|----------|-------------|
| `parseVersion(versionStr)` | Converts version string to comparable number |
| `parseGitHubDate(dateStr)` | Parses ISO 8601 date to timestamp |
| `getInstalledVersionDate()` | Extracts build date from installed version |
| `shouldCheckForUpdates()` | Checks if interval has elapsed |
| `checkForUpdates(silent)` | Main update check logic |
| `openDownloadPage(url)` | Opens browser to download page |
| `getUpdateStatus()` | Returns status string for UI |

## Future Considerations

- **Migration to SemVer**: The system is ready for a versioning scheme change without breaking update detection
- **Pre-release support**: Could be extended to check for beta/RC releases via `prerelease` flag
- **Auto-download**: Could be enhanced to download and extract updates automatically (requires additional permissions)

## Files Modified

| File | Changes |
|------|---------|
| `UpdateChecker.lua` | New file - update checking logic |
| `Init.lua` | Added require and startup check |
| `PluginInfoDialogSections.lua` | Added "Plugin Updates" UI section |
| `Info.lua` | VERSION table (existing, used as source of truth) |