--[[
   
    PWExtraOptions.lua

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

-- *************************************************
local function main()


     LrFunctionContext.callWithContext("PWExtraOptionsContext", function(context)
            -- Create a property table inside the context
            
            log:info("PWExtraOptions - icons is at " .. _PLUGIN.path .. '/icons/icon.png')

            local props = LrBinding.makePropertyTable(context)
            local bind = LrView.bind
            props.createCollectionsForSets = false
            props.tagRoot = "Piwigo"


            local f = LrView.osFactory()
            local c = f:column {
                spacing = f:dialog_spacing(),

                f:row {
                    spacing = 10,
                    f:picture {
                        file = _PLUGIN.path .. '/icons/icon.png',
                        width = 48, height = 48,
                        alignment = 'left',
                        tooltip = "Piwigo Logo",
                    },
                    f:static_text {
                        title = "Piwigo Extra Options",
                        alignment = 'left',
                        fill_horizontal = 1,
                    },
                },

                f:separator { fill_horizontal = 1 },

                f:row {
                    f:checkbox {
                        title = "Create Publish Collections for Sets",
                        value = bind 'createCollectionsForSets',
                        tooltip = "When enabled, Piwigo album sets will become publish collections in Lightroom.",
                    },
                },

                f:row {
                    f:static_text {
                        title = "Root Keyword Tag for Published Photos:",
                        width = 200,
                        alignment = 'right',
                    },
                    f:edit_field {
                        value = bind 'tagRoot',
                        width_in_chars = 30,
                        immediate = true,
                        tooltip = "The top-level keyword tag for photos published to Piwigo.",
                    },
                },

                f:spacer { height = 10 },

                f:row {
                    spacing = 10,
                    f:push_button {
                        title = "Apply",
                        action = function()
                            LrDialogs.message(
                                "Settings applied",
                                "Checkbox: " .. tostring(props.createCollectionsForSets) ..
                                "\nRoot tag: " .. tostring(props.tagRoot)
                            )
                        end,
                    },
                    f:push_button {
                        title = "Close",
                        action = function()
                            dialog:close()
                        end,
                    },
                },
            }

            dialog = LrDialogs.presentModalDialog({
                title = "Piwigo Extra Options",
                contents = c,
                actionVerb = "Close",
            })
    end)
end

-- *************************************************
-- Run main()
LrTasks.startAsyncTask(main)