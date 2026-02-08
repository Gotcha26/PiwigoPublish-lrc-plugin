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
-- NOTE: Currently not exposed in the GUI but kept for potential future use
local function resetPluginPrefs(prefix)
    log:info("resetPluginPrefs \n" .. utils.serialiseVar(prefs))
    for k, p in prefs:pairs() do
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
    propertyTable.checkUpdatesOnStartup = prefs.checkUpdatesOnStartup
end

-- *************************************************
function PluginInfoDialogSections.sectionsForBottomOfDialog(f, propertyTable)
    local bind = LrView.bind
    local share = LrView.share

    return {
        -- ===================================
        -- SELF UPDATE SECTION
        -- ===================================
        {
            bind_to_object = propertyTable,
            title = "Self Update",

            f:row {
                f:checkbox {
                    value = bind 'checkUpdatesOnStartup',
                    title = "Check for updates to this plugin when Lightroom starts",
                },
            },

            f:row {
                f:push_button {
                    title = "Check for updates now",
                    action = function()
                        UpdateChecker.checkForUpdates(false) -- silent = false
                    end,
                },
            },
        },

        -- ===================================
        -- DEBUGGING SECTION
        -- ===================================
        {
            bind_to_object = propertyTable,
            title = "Debugging",

            f:row {
                f:static_text {
                    title = "If you have a problem with Piwigo Publisher then I'll probably ask you to activate the debug logging. This will save all sorts of useful information into a file.",
                    width_in_chars = 60,
                    height_in_lines = 2,
                    alignment = 'left',
                },
            },

            f:row {
                spacing = f:label_spacing(),

                f:radio_button {
                    value = bind 'debugEnabled',
                    checked_value = false,
                    title = "Do not log debug information",
                },
            },

            f:row {
                spacing = f:label_spacing(),

                f:radio_button {
                    value = bind 'debugEnabled',
                    checked_value = true,
                    title = "Log debug information to a file (PiwigoPublishPlugin.log) in your Lightroom logs folder",
                },
            },

            f:row {
                spacing = f:label_spacing(),

                f:push_button {
                    title = "Show logfile",
                    enabled = bind 'debugEnabled',
                    action = function()
                        LrShell.revealInShell(utils.getLogfilePath())
                    end,
                },
            },
        },

        -- ===================================
        -- STATUS SECTION
        -- ===================================
        {
            bind_to_object = propertyTable,
            title = "Status",

            f:row {
                f:column {
                    f:picture {
                        alignment = 'left',
                        value = iconPath,
                    },
                },
                f:column {
                    spacing = f:control_spacing(),

                    f:static_text {
                        title = "Piwigo Publisher",
                        alignment = 'left',
                        font = "<system/bold>",
                    },

                    f:row {
                        f:static_text {
                            title = "Version:",
                            alignment = 'right',
                            width = share 'label_width',
                        },
                        f:static_text {
                            title = pluginVersion,
                            alignment = 'left',
                        },
                    },

                    f:row {
                        f:static_text {
                            title = "Update Status:",
                            alignment = 'right',
                            width = share 'label_width',
                        },
                        f:static_text {
                            title = bind 'updateStatus',
                            alignment = 'left',
                        },
                    },

                    f:row {
                        f:static_text {
                            title = "Plugin page:",
                            alignment = 'right',
                            width = share 'label_width',
                        },
                        f:column {
                            f:static_text {
                                title = GITHUB_URL,
                                alignment = 'left',
                                text_color = LrColor("blue"),
                                mouse_down = function()
                                    LrHttp.openUrlInBrowser(GITHUB_URL)
                                end,
                            },
                            f:push_button {
                                title = "Visit...",
                                action = function()
                                    LrHttp.openUrlInBrowser(GITHUB_URL)
                                end,
                            },
                        },
                    },
                },
            },
        },

        -- ===================================
        -- ACKNOWLEDGEMENTS SECTION
        -- ===================================
        {
            bind_to_object = propertyTable,
            title = "Acknowledgements",

            f:row {
                f:static_text {
                    title = "Developer:",
                    alignment = 'right',
                    width = share 'ack_label_width',
                    font = "<system/bold>",
                },
                f:static_text {
                    title = "Fiona Boston",
                    alignment = 'left',
                },
            },

            f:row {
                f:spacer { width = share 'ack_label_width' },
                f:static_text {
                    title = "fiona@fbphotography.uk",
                    alignment = 'left',
                    text_color = LrColor("blue"),
                    mouse_down = function()
                        LrHttp.openUrlInBrowser("mailto:fiona@fbphotography.uk")
                    end,
                },
            },

            f:row {
                f:static_text {
                    title = string.rep("─", 70),
                    alignment = 'left',
                    text_color = LrColor("black"),
                },
            },

            f:row {
                f:static_text {
                    title = "Contributor:",
                    alignment = 'right',
                    width = share 'ack_label_width',
                    font = "<system/bold>",
                },
                f:static_text {
                    title = "Julien Moreau",
                    alignment = 'left',
                },
            },

            f:row {
                f:spacer { width = share 'ack_label_width' },
                f:static_text {
                    title = "contact@julien-moreau.fr",
                    alignment = 'left',
                    text_color = LrColor("blue"),
                    mouse_down = function()
                        LrHttp.openUrlInBrowser("mailto:contact@julien-moreau.fr")
                    end,
                },
            },

            f:row {
                f:spacer { width = share 'ack_label_width' },
                f:static_text {
                    title = "https://julien-moreau.fr",
                    alignment = 'left',
                    text_color = LrColor("blue"),
                    mouse_down = function()
                        LrHttp.openUrlInBrowser("https://julien-moreau.fr")
                    end,
                },
            },
        },
    }
end

-- *************************************************
function PluginInfoDialogSections.endDialog(propertyTable)
    prefs.debugEnabled = propertyTable.debugEnabled
    prefs.checkUpdatesOnStartup = propertyTable.checkUpdatesOnStartup

    -- Apply debug settings
    if prefs.debugEnabled then
        log:enable("logfile")
    else
        log:disable()
    end
end
