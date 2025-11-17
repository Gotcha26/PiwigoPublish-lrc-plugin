--[[

    PiwigoOpQueue.lua

    lua functions to accss the Piwigo Web API
    see https://github.com/Piwigo/Piwigo/wiki/Piwigo-Web-API

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

local PiwigoOpQueue = {}

-- -------------------------------------------------------------------
-- INTERNAL STATE
-- -------------------------------------------------------------------
local queue = {}
local running = false      -- true when an operation is in progress
local uiBusy = false       -- external-facing busy flag for UI

-- *************************************************
function PiwigoOpQueue.isBusy()
-- -------------------------------------------------------------------
-- PUBLIC: Check if UI should block actions
-- -------------------------------------------------------------------

    return uiBusy or running
end

-- *************************************************
function PiwigoOpQueue.enqueue(opName, fn)
-- -------------------------------------------------------------------
-- PUBLIC: Enqueue a function to be run serially.
--         The function must return (ok, result) like pcall.
-- -------------------------------------------------------------------

    table.insert(queue, { name = opName, fn = fn })
    PiwigoOpQueue._kick()
end

-- *************************************************
function PiwigoOpQueue._kick()
-- -------------------------------------------------------------------
-- INTERNAL: Start processing queue if not already running.
-- -------------------------------------------------------------------

    if running then
        return
    end

    running = true

    LrTasks.startAsyncTask(function()
        while #queue > 0 do
            local job = table.remove(queue, 1)

            uiBusy = true  -- UI should block during the job

            local ok, result = pcall(job.fn)

            uiBusy = false

            if not ok then
                -- You can log or alert here if needed
                -- LrDialogs.message("Piwigo error", result)
            end
        end

        running = false
    end)
end

-- *************************************************
return PiwigoOpQueue