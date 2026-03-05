--[[

	PluginInfoDialogSections.lua

	Plugin Manager Dialog Sections for Piwigo Publisher plugin

    Copyright (C) 2024 Fiona Boston <fiona@fbphotography.uk>.

    This file is part of PiwigoPublish

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

---@diagnostic disable: undefined-global

local LrHttp = import 'LrHttp'

PluginInfoDialogSections = {}

-- *************************************************
-- CONSTANTS
-- *************************************************
local GITHUB_URL = "https://github.com/Piwigo/PiwigoPublish-lrc-plugin"

-- *************************************************
-- HELPER FUNCTIONS
-- *************************************************
-- Reset plugin preferences (optionally filtered by prefix)
local function resetPluginPrefs(prefix)
    log:info("resetPluginPrefs \n" .. utils.serialiseVar(prefs))
    for k, _ in prefs:pairs() do
        if prefix then
            if k:find(prefix, 1, true) == 1 then
                prefs[k] = nil
            end
        else
            prefs[k] = nil
        end
    end
end

-- *************************************************
-- DIALOG LIFECYCLE
-- *************************************************
function PluginInfoDialogSections.startDialog(propertyTable)
    -- Initialize update status
    propertyTable.updateStatus = UpdateChecker.getUpdateStatus()

    -- Initialize debug preferences
    if prefs.debugEnabled == nil then
        prefs.debugEnabled = false
    end
    if prefs.clearLogOnReload == nil then
        prefs.clearLogOnReload = false
    end

    -- Initialize update check preference
    if prefs.checkUpdatesOnStartup == nil then
        prefs.checkUpdatesOnStartup = true
    end

    -- Apply debug settings
    if prefs.debugEnabled then
        log:enable("logfile")
    else
        log:disable()
    end

    propertyTable.debugEnabled = prefs.debugEnabled
    propertyTable.clearLogOnReload = prefs.clearLogOnReload
    propertyTable.checkUpdatesOnStartup = prefs.checkUpdatesOnStartup
end

-- *************************************************
function PluginInfoDialogSections.sectionsForTopOfDialog(f, propertyTable)
    local bind = LrView.bind
    local share = LrView.share

    return {
        -- ===================================
        -- SECTION 1: PLUG-IN INFO
        -- ===================================
        {
            bind_to_object = propertyTable,
            title = "Plug-in Info",
            synopsis = "Piwigo Publisher Plugin  •  Version " .. pluginVersion,
            fill = 1,
            spacing = f:control_spacing(),

            -- Two-column header layout (left: icon+identity, right: credits)
            f:row {
                spacing = f:dialog_spacing(),

                -- Left column: icon + plugin identity
                f:column {
                    spacing = f:control_spacing(),

                    f:row {
                        spacing = f:control_spacing(),

                        f:picture {
                            alignment = 'left',
                            value = iconPath,
                        },

                        f:column {
                            spacing = f:label_spacing(),

                            f:static_text {
                                title = "Piwigo Publisher",
                                font = "<system/bold>",
                                alignment = 'left',
								width = 250,
                            },

                            -- Version @ UpdateStatus on one line, red if not up to date
                            f:view {
                                bind_to_object = propertyTable,
                                f:static_text {
                                    title = LrView.bind {
                                        key = 'updateStatus',
                                        transform = function(value)
                                            return pluginVersion .. "  @  " .. (value or "")
                                        end,
                                    },
                                    font = "<system/small>",
                                    text_color = LrView.bind {
                                        key = 'updateStatus',
                                        transform = function(value)
                                            if value and value ~= "Up to date" then
                                                return LrColor(0.8, 0, 0)
                                            end
                                            return LrColor(0.5, 0.5, 0.5)
                                        end,
                                    },
                                    alignment = 'left',
                                },
                            },
                        },
                    },

                    f:row {
                        f:spacer { fill_horizontal = 1 },
                        f:push_button {
                            title = "Visit Plugin Page…",
                            action = function()
                                LrHttp.openUrlInBrowser(GITHUB_URL)
                            end,
                        },
                        f:spacer { fill_horizontal = 1 },
                    },

                    f:row {
                        f:static_text {
                            title = "Made in England with cider and cheddar cheese in Somerset,\n" ..
                                    "the Land of the Summer People.",
                            font = "<system/small/italic>",
                            text_color = LrColor(0.5, 0.5, 0.5),
                            alignment = 'center',
                            fill_horizontal = 1,
                            height_in_lines = -1,
                        },
                    },
                },

                -- Right column: credits (no outer border — plain column)
                f:column {
                    fill_horizontal = 1,
                    spacing = f:label_spacing(),
                    margin_left = f:dialog_spacing(),

                    -- Developer row
                    f:row {
                        spacing = f:control_spacing(),
                        f:static_text {
                            title = "Developer:",
                            width = share 'credit_label_width',
                            alignment = 'right',
                        },
                        f:column {
                            spacing = f:label_spacing(),
                            f:static_text {
                                title = "Fiona Boston",
                                alignment = 'left',
                            },
                            f:static_text {
                                title = "fiona@fbphotography.uk",
                                alignment = 'left',
                                text_color = LrColor("blue"),
                                mouse_down = function()
                                    LrHttp.openUrlInBrowser("mailto:fiona@fbphotography.uk")
                                end,
                            },
                            f:push_button {
                                title = "Visit website…",
                                action = function()
                                    LrHttp.openUrlInBrowser("https://gallery.fbphotography.uk/")
                                end,
                            },
                        },
                    },

                    f:separator { fill_horizontal = 1 },

                    -- Contributor row
                    f:row {
                        spacing = f:control_spacing(),
                        f:static_text {
                            title = "Contributor:",
                            width = share 'credit_label_width',
                            alignment = 'right',
                        },
                        f:column {
                            spacing = f:label_spacing(),
                            f:static_text {
                                title = "Julien Moreau",
                                alignment = 'left',
                            },
                            f:static_text {
                                title = "contact@julien-moreau.fr",
                                alignment = 'left',
                                text_color = LrColor("blue"),
                                mouse_down = function()
                                    LrHttp.openUrlInBrowser("mailto:contact@julien-moreau.fr")
                                end,
                            },
                            f:push_button {
                                title = "Visit website…",
                                action = function()
                                    LrHttp.openUrlInBrowser("https://julien-moreau.fr")
                                end,
                            },
                        },
                    },
                },
            },
        },

        -- ===================================
        -- SECTION 2: PLUG-IN PREFERENCES
        -- ===================================
        {
            bind_to_object = propertyTable,
            title = "Plug-in Preferences",
            fill = 1,
            spacing = f:control_spacing(),

            -- Updates group box
            f:group_box {
                title = "Updates ",
                fill_horizontal = 1,
                spacing = f:control_spacing(),

                f:row {
                    f:checkbox {
                        value = bind 'checkUpdatesOnStartup',
                        title = "Check for updates when Lightroom starts",
                    },
                    f:spacer { fill_horizontal = 1 },
                    f:push_button {
                        title = "Check now",
                        action = function()
                            UpdateChecker.checkForUpdates(false)
                        end,
                    },
                },
            },

            -- Debug logging group box
            f:group_box {
                title = "Diagnostic Logging ",
                fill_horizontal = 1,
                spacing = f:control_spacing(),

                f:row {
                    fill_horizontal = 1,
                    f:static_text {
                        title = "If you experience a problem, enable logging, reproduce the issue,\n" ..
                                "then share the log files with support.",
                        fill_horizontal = 1,
                        height_in_lines = 2,
                        alignment = 'left',
                        text_color = LrColor(0.02, 0.15, 0.39),
                    },
                },

                f:row {
                    f:checkbox {
                        value = bind 'debugEnabled',
                        title = "Enable logging",
                    },
                    f:spacer { fill_horizontal = 1 },
                },

                f:row {
                    f:push_button {
                        title = "Open log files",
                        enabled = bind 'debugEnabled',
                        action = function()
                            LrShell.revealInShell(LrPathUtils.parent(utils.getLogfilePath()))
                        end,
                    },
                    f:push_button {
                        title = "Clear log files",
                        action = function()
                            local ok = utils.clearLogFiles()
                            LrDialogs.message(
                                "Log file cleared",
                                ok and "Done." or "Could not clear log file.",
                                "info"
                            )
                        end,
                    },
                    f:spacer { fill_horizontal = 1 },
                },

                f:row {
                    spacing = f:dialog_spacing(),
                    f:picture {
                        value = _PLUGIN:resourceId('icons/email_32.png'),
                    },
                    f:push_button {
                        title = "Report by email",
                        action = function()
                            LrShell.revealInShell(LrPathUtils.parent(utils.getLogfilePath()))
                            LrHttp.openUrlInBrowser("mailto:contact@fbphotography.uk?subject=PiwigoPublish%20issue&body=Please%20attach%20the%20log%20file.")
                        end,
                    },
                    f:spacer { width = 16 },
                    f:picture {
                        value = _PLUGIN:resourceId('icons/github_32.png'),
                    },
                    f:push_button {
                        title = "Report via GitHub",
                        action = function()
                            LrShell.revealInShell(LrPathUtils.parent(utils.getLogfilePath()))
                            LrHttp.openUrlInBrowser("https://github.com/Piwigo/PiwigoPublish-lrc-plugin/issues/new")
                        end,
                    },
                    f:spacer { fill_horizontal = 1 },
                },
            },

            -- Unsafe / developer group box
            f:group_box {
                title = "Unsafe area — Development only ",
                fill_horizontal = 1,
                spacing = f:control_spacing(),

                f:row {
                    fill_horizontal = 1,
                    f:static_text {
                        title = "Intended for plugin development and troubleshooting only.",
                        fill_horizontal = 1,
                        alignment = 'left',
                        text_color = LrColor(0.85, 0.45, 0),
                    },
                    f:push_button {
                        title = "Reset Preferences…",
                        action = function()
                            local result = LrDialogs.confirm(
                                "Reset Plugin Preferences",
                                "This will delete all saved settings for this plugin.\n\n" ..
                                "This cannot be undone.",
                                "Reset",
                                "Cancel"
                            )
                            if result == "ok" then
                                resetPluginPrefs()
                                LrDialogs.message(
                                    "Preferences Reset",
                                    "Plugin preferences have been cleared.",
                                    "info"
                                )
                            end
                        end,
                    },
                },

                f:row {
                    f:checkbox {
                        value = bind 'clearLogOnReload',
                        title = "Clear log file on plugin reload",
                    },
                    f:spacer { fill_horizontal = 1 },
                },
            },
        },

    }
end

-- *************************************************
function PluginInfoDialogSections.endDialog(propertyTable)
    prefs.debugEnabled = propertyTable.debugEnabled
    prefs.clearLogOnReload = propertyTable.clearLogOnReload
    prefs.checkUpdatesOnStartup = propertyTable.checkUpdatesOnStartup

    -- Apply debug settings
    if prefs.debugEnabled then
        log:enable("logfile")
    else
        log:disable()
    end
end
