#!/bin/bash
# Path to your development plugin
SRC="/Volumes/EXT-Data/Nextcloud/github/lrc-plugins/PiwigoPublish/piwigoPublish.lrplugin"

# Path to Lightroom’s plugin folder (where LrC loads it)
DEST="/Volumes/EXT-Data/Data/Adobe/Lightroom/Plugins/MyPlugins/piwigoPublish.lrplugin"

# Copy while preserving structure, but overwrite changed files
rsync -av --delete "$SRC/" "$DEST/"
echo "✅ Plugin deployed to Lightroom folder."