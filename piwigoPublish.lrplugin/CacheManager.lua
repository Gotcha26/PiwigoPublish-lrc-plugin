--[[
    CacheManager.lua

    Simple in-memory cache with TTL for reducing redundant HTTP calls.
    Part of PiwigoPublish optimization (Étape 1A).

    Copyright (C) 2024 Fiona Boston <fiona@fbphotography.uk>.

    This file is part of PiwigoPublish

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.
]]

local CacheManager = {}

-- Internal cache storage
-- Structure: { [cacheKey] = { data = ..., expires = timestamp } }
local _cache = {}

-- Default TTL in seconds (5 minutes)
local DEFAULT_TTL = 300

-- *************************************************
-- Get current timestamp (seconds since epoch)
-- *************************************************
local function now()
    return os.time()
end

-- *************************************************
-- Generate cache key from function name and arguments
-- *************************************************
function CacheManager.makeKey(funcName, ...)
    local parts = { funcName }
    for i = 1, select('#', ...) do
        local v = select(i, ...)
        if v == nil then
            parts[#parts + 1] = "nil"
        elseif type(v) == "table" then
            -- For propertyTable, use pwurl as identifier
            if v.pwurl then
                parts[#parts + 1] = tostring(v.pwurl)
            else
                parts[#parts + 1] = "table"
            end
        else
            parts[#parts + 1] = tostring(v)
        end
    end
    return table.concat(parts, "::")
end

-- *************************************************
-- Get cached value if valid (not expired)
-- Returns: value, found (boolean)
-- *************************************************
function CacheManager.get(key)
    local entry = _cache[key]
    if entry and entry.expires > now() then
        return entry.data, true
    end
    -- Expired or not found - clean up if expired
    if entry then
        _cache[key] = nil
    end
    return nil, false
end

-- *************************************************
-- Set cache value with optional TTL
-- *************************************************
function CacheManager.set(key, value, ttl)
    ttl = ttl or DEFAULT_TTL
    _cache[key] = {
        data = value,
        expires = now() + ttl
    }
end

-- *************************************************
-- Invalidate a specific cache key
-- *************************************************
function CacheManager.invalidate(key)
    _cache[key] = nil
end

-- *************************************************
-- Invalidate all keys matching a pattern (prefix)
-- *************************************************
function CacheManager.invalidatePrefix(prefix)
    for key in pairs(_cache) do
        if key:sub(1, #prefix) == prefix then
            _cache[key] = nil
        end
    end
end

-- *************************************************
-- Clear entire cache
-- *************************************************
function CacheManager.clear()
    _cache = {}
end

-- *************************************************
-- Get cache statistics (for debugging)
-- *************************************************
function CacheManager.stats()
    local count = 0
    local valid = 0
    local currentTime = now()
    for _, entry in pairs(_cache) do
        count = count + 1
        if entry.expires > currentTime then
            valid = valid + 1
        end
    end
    return { total = count, valid = valid }
end

return CacheManager
