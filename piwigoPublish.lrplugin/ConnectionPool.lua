--[[
    ConnectionPool.lua

    Manages Piwigo session connections to avoid redundant logins.
    Part of PiwigoPublish optimization (Étape 2B).

    Strategy:
    1. Cache session credentials per host
    2. Track session validity with timestamps
    3. Verify session before reuse, re-login only if expired
    4. Session timeout: 20 minutes (Piwigo default is 30 min)

    Copyright (C) 2024 Fiona Boston <fiona@fbphotography.uk>.

    This file is part of PiwigoPublish

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.
]]

local ConnectionPool = {}

-- Session storage by host
-- Structure: { [host] = { cookies, cookieHeader, SessionCookie, token, userStatus, lastActivity, userName } }
local _sessions = {}

-- Session timeout in seconds (20 minutes)
local SESSION_TIMEOUT = 1200

-- *************************************************
-- Get current timestamp
-- *************************************************
local function now()
    return os.time()
end

-- *************************************************
-- Generate session key from host and username
-- *************************************************
local function makeSessionKey(host, userName)
    return (host or "") .. "::" .. (userName or "")
end

-- *************************************************
-- Check if a session is still valid (not expired)
-- *************************************************
function ConnectionPool.isSessionValid(host, userName)
    local key = makeSessionKey(host, userName)
    local session = _sessions[key]

    if not session then
        return false
    end

    -- Check if session has expired
    if (now() - session.lastActivity) > SESSION_TIMEOUT then
        log:info("ConnectionPool - session expired for " .. key)
        _sessions[key] = nil
        return false
    end

    return true
end

-- *************************************************
-- Store session data after successful login
-- *************************************************
function ConnectionPool.storeSession(propertyTable)
    local key = makeSessionKey(propertyTable.host, propertyTable.userName)

    _sessions[key] = {
        cookies = propertyTable.cookies,
        cookieHeader = propertyTable.cookieHeader,
        SessionCookie = propertyTable.SessionCookie,
        token = propertyTable.token,
        userStatus = propertyTable.userStatus,
        lastActivity = now(),
        userName = propertyTable.userName
    }

    log:info("ConnectionPool - stored session for " .. key)
end

-- *************************************************
-- Restore session data to propertyTable if valid
-- Returns: true if session restored, false if need new login
-- *************************************************
function ConnectionPool.restoreSession(propertyTable)
    local key = makeSessionKey(propertyTable.host, propertyTable.userName)
    local session = _sessions[key]

    if not session then
        log:info("ConnectionPool - no cached session for " .. key)
        return false
    end

    -- Check if session has expired
    if (now() - session.lastActivity) > SESSION_TIMEOUT then
        log:info("ConnectionPool - session expired for " .. key)
        _sessions[key] = nil
        return false
    end

    -- Restore session data
    propertyTable.cookies = session.cookies
    propertyTable.cookieHeader = session.cookieHeader
    propertyTable.SessionCookie = session.SessionCookie
    propertyTable.token = session.token
    propertyTable.userStatus = session.userStatus
    propertyTable.Connected = true

    -- Update last activity
    session.lastActivity = now()

    log:info("ConnectionPool - restored session for " .. key)
    return true
end

-- *************************************************
-- Update session activity timestamp (call after each successful API call)
-- *************************************************
function ConnectionPool.touch(host, userName)
    local key = makeSessionKey(host, userName)
    local session = _sessions[key]

    if session then
        session.lastActivity = now()
    end
end

-- *************************************************
-- Invalidate session for a host (call on auth failure)
-- *************************************************
function ConnectionPool.invalidate(host, userName)
    local key = makeSessionKey(host, userName)
    _sessions[key] = nil
    log:info("ConnectionPool - invalidated session for " .. key)
end

-- *************************************************
-- Clear all sessions
-- *************************************************
function ConnectionPool.clear()
    _sessions = {}
    log:info("ConnectionPool - cleared all sessions")
end

-- *************************************************
-- Get statistics
-- *************************************************
function ConnectionPool.stats()
    local count = 0
    local valid = 0
    local currentTime = now()

    for key, session in pairs(_sessions) do
        count = count + 1
        if (currentTime - session.lastActivity) <= SESSION_TIMEOUT then
            valid = valid + 1
        end
    end

    return { total = count, valid = valid }
end

return ConnectionPool
