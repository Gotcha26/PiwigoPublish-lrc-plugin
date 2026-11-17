--[[

    PWConnectionManager.lua

    One Piwigo session shared by every task of the plugin (issue #16, upstream #76).

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

--[[
Why: LrHttp keeps one cookie store for the whole application. A second pwg.session.login sends
the pwg_id of the session another task is still using, and Piwigo's session_regenerate_id(true)
deletes it: that task then fails with 401 / "Invalid security token".

How:
- the session (cookies + pwg_token) is kept in plugin prefs, keyed by host + user, because
  Lightroom runs each publish in its own Lua environment (module tables are not shared);
- a task reuses it; it is re-checked with pwg.session.getStatus (no new login) when it has not
  been checked for VALIDATE_AFTER seconds;
- only one task logs in at a time (login lock in prefs, abandoned after LOCK_STALE seconds);
- a session is only reused with the same password (MD5 fingerprint), so a wrong password typed in
  the dialog is never hidden by a still-valid session;
- sessions and the lock are wiped at plugin start and at Lightroom shutdown.
]]

local PWConnectionManager = {}

local VALIDATE_AFTER = 300  -- seconds without check before a reused session is re-checked
local LOCK_STALE = 45       -- seconds after which a login lock is considered abandoned
local LOCK_WAIT_MAX = 60    -- seconds a task waits for another task's login
local LOCK_KEY = "piwigoLoginLock"
local SESSION_PREFIX = "piwigoSession_"
local connecting = {} -- [sessionKey] = true while this environment runs pwConnect for it

-- *************************************************
local function sharedPrefs()
    return import 'LrPrefs'.prefsForPlugin()
end

-- *************************************************
local function sessionKey(pt)
    return SESSION_PREFIX .. string.lower(tostring(pt.host or "")) .. "_" .. string.lower(tostring(pt.userName or ""))
end

-- *************************************************
local function pwHash(pt)
    return LrMD5.digest(tostring(pt.userPW or ""))
end

-- *************************************************
-- stored session usable by this propertyTable (same host, user and password), or nil
local function storedSession(pt)
    local s = sharedPrefs()[sessionKey(pt)]
    if type(s) ~= "table" or utils.nilOrEmpty(s.cookieHeader) or utils.nilOrEmpty(s.token) then
        return nil
    end
    if s.host ~= pt.host or s.userName ~= pt.userName or s.pwHash ~= pwHash(pt) then
        return nil
    end
    return s
end

-- *************************************************
local function adopt(pt, s)
    pt.pwurl = pt.host .. "/ws.php?format=json"
    pt.cookieHeader = s.cookieHeader
    pt.SessionCookie = s.SessionCookie
    pt.cookies = s.cookies
    pt.token = s.token
    pt.userStatus = s.userStatus
    pt.pwVersion = s.pwVersion
    pt.Connected = true
    pt.ConCheck = false
    pt.ConStatus = "Connected to your Piwigo gallery v" .. tostring(s.pwVersion or "unknown")
end

-- *************************************************
-- store the session held in pt (called by PiwigoAPI.pwConnect right after a successful login)
function PWConnectionManager.storeSession(pt)
    if utils.nilOrEmpty(pt.cookieHeader) or utils.nilOrEmpty(pt.token) then
        return false
    end
    local now = os.time()
    -- always assign a new table so the change is persisted
    sharedPrefs()[sessionKey(pt)] = {
        cookieHeader = pt.cookieHeader,
        SessionCookie = pt.SessionCookie,
        cookies = pt.cookies,
        token = pt.token,
        userStatus = pt.userStatus,
        pwVersion = pt.pwVersion,
        host = pt.host,
        userName = pt.userName,
        pwHash = pwHash(pt),
        savedAt = now,
        validatedAt = now,
    }
    log:info("PWConnectionManager.storeSession - stored session for " .. sessionKey(pt))
    return true
end

-- *************************************************
-- forget the stored session. With failedCookie, only if it is still that one: a late failure must
-- not wipe a newer session another task has just created.
function PWConnectionManager.invalidate(pt, failedCookie)
    local key = sessionKey(pt)
    local s = sharedPrefs()[key]
    if type(s) == "table" and (failedCookie == nil or s.cookieHeader == failedCookie) then
        sharedPrefs()[key] = nil
        log:info("PWConnectionManager.invalidate - cleared session for " .. key)
    end
    if failedCookie == nil or pt.cookieHeader == failedCookie then
        pt.Connected = false
    end
end

-- *************************************************
-- reuse the stored session if it is still alive; true if pt is now connected with it
local function tryReuse(pt)
    local s = storedSession(pt)
    if not s then
        return false
    end
    if pt.Connected and pt.cookieHeader == s.cookieHeader then
        return true -- fast path: already on the shared session, no HTTP call
    end
    if os.time() - (s.validatedAt or 0) > VALIDATE_AFTER then
        local alive = PiwigoAPI.pwSessionCheck(pt, s.cookieHeader)
        if not alive then
            log:info("PWConnectionManager - stored session no longer valid, discarding it")
            PWConnectionManager.invalidate(pt, s.cookieHeader)
            return false
        end
        local refreshed = {}
        for k, v in pairs(s) do refreshed[k] = v end
        refreshed.validatedAt = os.time()
        sharedPrefs()[sessionKey(pt)] = refreshed
        s = refreshed
    end
    adopt(pt, s)
    log:info("PWConnectionManager - reusing shared session for " .. sessionKey(pt))
    return true
end

-- *************************************************
local function lockIsFree(lock)
    return type(lock) ~= "table" or (os.time() - (lock.at or 0) > LOCK_STALE)
end

-- *************************************************
-- connected propertyTable on return, or false. Logs in only when no shared session is usable.
function PWConnectionManager.ensureConnection(pt)
    if utils.nilOrEmpty(pt.host) or utils.nilOrEmpty(pt.userName) or utils.nilOrEmpty(pt.userPW) then
        log:info("PWConnectionManager.ensureConnection - missing host, username or password")
        return false
    end
    -- re-entrancy: pwConnect itself calls code that logs in (getTagList, checkAdmin, server plugin
    -- probe), possibly through another propertyTable (effectivePT). If the session could not be
    -- stored (no pwg cookie / token), those nested calls must not wait for our own lock and log in
    -- again, endlessly. Keyed by host+user, since the nested call may use another table.
    if connecting[sessionKey(pt)] then
        return pt.Connected and true or false
    end
    if tryReuse(pt) then
        return true
    end

    -- serialise logins: wait for another task's login and reuse its session
    local me = tostring({}) .. "@" .. tostring(os.clock())
    local waited = 0
    while true do
        local p = sharedPrefs()
        if lockIsFree(p[LOCK_KEY]) then
            p[LOCK_KEY] = { owner = me, at = os.time() } -- test-and-set, no yield in between
            break
        end
        if waited >= LOCK_WAIT_MAX then
            log:info("PWConnectionManager.ensureConnection - login lock still held after " ..
                LOCK_WAIT_MAX .. "s, logging in anyway")
            break
        end
        LrTasks.sleep(0.25)
        waited = waited + 0.25
        if tryReuse(pt) then
            return true
        end
    end

    -- another task may have logged in between our last check and taking the lock
    local key = sessionKey(pt)
    local ok, rv = LrTasks.pcall(function()
        if tryReuse(pt) then
            return true
        end
        log:info("PWConnectionManager.ensureConnection - logging in for " .. key)
        connecting[key] = true
        return PiwigoAPI.pwConnect(pt)
    end)
    connecting[key] = nil
    local p = sharedPrefs()
    if type(p[LOCK_KEY]) == "table" and p[LOCK_KEY].owner == me then
        p[LOCK_KEY] = nil
    end
    if not ok then
        error(rv, 0)
    end
    return rv and true or false
end

-- *************************************************
-- after a 401 / rejected token: drop the failed session (unless already replaced) and reconnect,
-- reusing a newer session if another task has one
function PWConnectionManager.renew(pt, failedCookie)
    PWConnectionManager.invalidate(pt, failedCookie or pt.cookieHeader)
    pt.Connected = false
    return PWConnectionManager.ensureConnection(pt)
end

-- *************************************************
-- wipe every stored session and the login lock (plugin start, Lightroom shutdown)
function PWConnectionManager.clearAll()
    local p = sharedPrefs()
    local stale = {}
    -- LrPrefs is a proxy: iterate with its documented pairs() method, not Lua's pairs()
    for k in p:pairs() do
        if type(k) == "string" and string.sub(k, 1, #SESSION_PREFIX) == SESSION_PREFIX then
            stale[#stale + 1] = k
        end
    end
    for _, k in ipairs(stale) do
        p[k] = nil
    end
    p[LOCK_KEY] = nil
    log:info("PWConnectionManager.clearAll - cleared " .. #stale .. " stored session(s)")
    return #stale
end

-- *************************************************
return PWConnectionManager
