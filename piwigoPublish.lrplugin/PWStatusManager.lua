--[[

    PWStatusManager.lua

    Copyright (C) 2025 Fiona Boston <fiona@fbphotography.uk>.

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

--*******************************************
-- manage service status between functions

local PWStatusManager = {}

local pwServiceState = {}
--*******************************************
local function ensureState(publishService)
    local id = publishService.localIdentifier
    local state = pwServiceState[id]
    if not state then
        state = {
            PiwigoBusy = false,
            RenderPhotos = false,
            isCloningSync = false,
            RemoteInfoTable = {},
        }
        pwServiceState[id] = state
        log:info("PWStatusManager: created new state for service " .. id)
    end
    return state
end

--*******************************************
function PWStatusManager.getServiceState(publishService)
    -- manage per publish service status flags
    return ensureState(publishService)
end

--*******************************************
-- #16: "Piwigo busy" lock shared by every task of the plugin.
-- The table above lives in one Lua environment, and Lightroom may run publish callbacks in
-- separate ones, so the lock itself is kept in plugin prefs: owner token + label + heartbeat.
-- Only the holder (token) releases it. A lock without heartbeat for BUSY_STALE_SECONDS is treated
-- as abandoned (hung task); after a crash it is wiped at plugin start (clearBusy in Init.lua).
local BUSY_STALE_SECONDS = 1800
local BUSY_OWNER, BUSY_LABEL, BUSY_TIME = "piwigoBusyOwner", "piwigoBusyLabel", "piwigoBusyTime"
local heldTokens = {} -- tokens acquired from this environment

local function sharedPrefs()
    return import 'LrPrefs'.prefsForPlugin()
end

local function currentOwner()
    local p = sharedPrefs()
    local owner = p[BUSY_OWNER]
    if owner == nil or owner == "" then
        return nil
    end
    if os.time() - (p[BUSY_TIME] or 0) > BUSY_STALE_SECONDS then
        log:info("PWStatusManager - ignoring abandoned busy lock " .. tostring(owner) ..
            " (" .. tostring(p[BUSY_LABEL]) .. ")")
        return nil
    end
    return owner, p[BUSY_LABEL]
end

--*******************************************
-- true (+ label of the running operation) when any task holds the lock
function PWStatusManager.isPiwigoBusy()
    local owner, label = currentOwner()
    return owner ~= nil, label
end

--*******************************************
-- take the lock. Returns a token, or nil if it is held by another task.
-- opts.wait: seconds to wait for it (default 0, math.huge = until free or cancelled)
-- opts.isCanceled: function returning true to stop waiting
-- opts.onWait: function(label) called once when the task starts waiting
function PWStatusManager.acquireBusy(publishService, label, opts)
    opts = opts or {}
    local waitMax = opts.wait or 0
    local waited = 0
    local notified = false
    while true do
        local owner, ownerLabel = currentOwner()
        if not owner then
            -- test-and-set: no yielding call between the check above and these writes
            local token = tostring(publishService and publishService.localIdentifier or "?") .. ":" ..
                tostring({}) .. ":" .. tostring(os.clock())
            local p = sharedPrefs()
            p[BUSY_OWNER] = token
            p[BUSY_LABEL] = label or ""
            p[BUSY_TIME] = os.time()
            heldTokens[token] = true
            if publishService then
                ensureState(publishService).PiwigoBusy = true
            end
            log:info("PWStatusManager.acquireBusy - " .. tostring(label) .. " (" .. token .. ")")
            return token
        end
        if waited >= waitMax or (opts.isCanceled and opts.isCanceled()) then
            log:info("PWStatusManager.acquireBusy - REFUSED " .. tostring(label) ..
                ", busy with " .. tostring(ownerLabel))
            return nil, ownerLabel
        end
        if not notified and opts.onWait then
            notified = true
            opts.onWait(ownerLabel)
        end
        LrTasks.sleep(1)
        waited = waited + 1
    end
end

--*******************************************
-- release the lock if this token still holds it
function PWStatusManager.releaseBusy(token, publishService)
    if token == nil then
        return
    end
    heldTokens[token] = nil
    if publishService then
        ensureState(publishService).PiwigoBusy = false
    end
    local p = sharedPrefs()
    if p[BUSY_OWNER] == token then
        p[BUSY_OWNER] = ""
        p[BUSY_LABEL] = ""
        p[BUSY_TIME] = 0
        log:info("PWStatusManager.releaseBusy - " .. token)
    end
end

--*******************************************
-- heartbeat during a long operation; without token, refreshes a lock held from this environment
-- (lets deep code such as video chunk uploads keep the lock alive without passing the token)
function PWStatusManager.touchBusy(token)
    local p = sharedPrefs()
    local owner = p[BUSY_OWNER]
    if owner and owner ~= "" and (owner == token or (token == nil and heldTokens[owner])) then
        p[BUSY_TIME] = os.time()
    end
end

--*******************************************
-- wipe the lock (plugin start: no task can be running yet)
function PWStatusManager.clearBusy()
    local p = sharedPrefs()
    p[BUSY_OWNER] = ""
    p[BUSY_LABEL] = ""
    p[BUSY_TIME] = 0
end

--*******************************************
-- run fn() while holding the lock (released whatever happens, errors re-raised).
-- Returns false, label when the lock could not be taken; true, results... otherwise.
function PWStatusManager.withBusy(publishService, label, opts, fn)
    local token, ownerLabel = PWStatusManager.acquireBusy(publishService, label, opts)
    if not token then
        return false, ownerLabel
    end
    local res = { LrTasks.pcall(fn, token) }
    PWStatusManager.releaseBusy(token, publishService)
    if not res[1] then
        error(res[2], 0)
    end
    return true, unpack(res, 2)
end

--*******************************************
function PWStatusManager.setRenderPhotos(publishService, setValue)
    ensureState(publishService).RenderPhotos = setValue
end

--*******************************************
function PWStatusManager.setisCloningSync(publishService, setValue)
    ensureState(publishService).isCloningSync = setValue
end

--*******************************************
-- store remote info for a collection
function PWStatusManager.storeRemoteInfo(publishService, collId, RemoteInfoTable)
    local state = ensureState(publishService)
    state.RemoteInfoTable[collId] = RemoteInfoTable
end

--*******************************************
-- get remote info for a collection
function PWStatusManager.getRemoteInfo(publishService, collId)
    local state = ensureState(publishService)
    return state.RemoteInfoTable[collId]
end

--*******************************************
-- clear remote info for a collection
function PWStatusManager.clearRemoteInfo(publishService, collId)
    local state = ensureState(publishService)
    state.RemoteInfoTable[collId] = nil
end

--*******************************************
return PWStatusManager
