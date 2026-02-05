--[[
    MetadataBatcher.lua

    Batches metadata updates to reduce HTTP overhead.
    Part of PiwigoPublish optimization (Étape 1B).

    Strategy:
    1. Queue metadata updates instead of sending immediately
    2. Pre-collect all missing tags across queued items
    3. Create missing tags in one batch call
    4. Flush queued updates (still individual API calls, but with pre-resolved tags)

    Copyright (C) 2024 Fiona Boston <fiona@fbphotography.uk>.

    This file is part of PiwigoPublish

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.
]]

local MetadataBatcher = {}

-- Queue of pending metadata updates
-- Each entry: { propertyTable, lrPhoto, metaData }
local _queue = {}

-- Default batch size
local BATCH_SIZE = 10

-- *************************************************
-- Add a metadata update to the queue
-- Returns: queueSize (number of items in queue)
-- *************************************************
function MetadataBatcher.queue(propertyTable, lrPhoto, metaData)
    table.insert(_queue, {
        propertyTable = propertyTable,
        lrPhoto = lrPhoto,
        metaData = metaData
    })
    log:info("MetadataBatcher.queue - queued item, size now " .. #_queue)
    return #_queue
end

-- *************************************************
-- Get current queue size
-- *************************************************
function MetadataBatcher.size()
    return #_queue
end

-- *************************************************
-- Check if queue should be flushed (reached batch size)
-- *************************************************
function MetadataBatcher.shouldFlush()
    return #_queue >= BATCH_SIZE
end

-- *************************************************
-- Collect all unique missing tags from queued items
-- Returns: table of unique tag names that need to be created
-- *************************************************
local function collectMissingTags(propertyTable)
    local allMissingTags = {}
    local seen = {}

    for _, item in ipairs(_queue) do
        local tagString = item.metaData.tagString or ""
        if tagString ~= "" then
            local _, missingTags = utils.tagsToIds(propertyTable.tagTable or {}, tagString)
            for _, tag in ipairs(missingTags) do
                local normalizedTag = utils.normaliseWord(tag)
                if not seen[normalizedTag] then
                    seen[normalizedTag] = true
                    table.insert(allMissingTags, tag)
                end
            end
        end
    end

    return allMissingTags
end

-- *************************************************
-- Flush all queued metadata updates
-- Pre-creates missing tags, then sends all updates
-- Returns: results table { success = count, failed = count, errors = {} }
-- *************************************************
function MetadataBatcher.flush(propertyTable)
    local results = {
        success = 0,
        failed = 0,
        errors = {}
    }

    if #_queue == 0 then
        log:info("MetadataBatcher.flush - queue empty, nothing to flush")
        return results
    end

    log:info("MetadataBatcher.flush - flushing " .. #_queue .. " items")

    -- Step 1: Ensure we have the tag list
    if not propertyTable.tagTable then
        local rv
        rv, propertyTable.tagTable = PiwigoAPI.getTagList(propertyTable)
        if not rv then
            results.errors[#results.errors + 1] = "Cannot get tag list from Piwigo"
            -- Clear queue on critical error
            _queue = {}
            return results
        end
    end

    -- Step 2: Collect and create all missing tags in one batch
    local allMissingTags = collectMissingTags(propertyTable)
    if #allMissingTags > 0 then
        log:info("MetadataBatcher.flush - creating " .. #allMissingTags .. " missing tags in batch")
        local rv, newTagIds = PiwigoAPI.createTags(propertyTable, allMissingTags)
        if rv then
            log:info("MetadataBatcher.flush - created tags: " .. utils.tabletoString(newTagIds, ","))
        else
            log:warn("MetadataBatcher.flush - failed to create some tags")
        end
        -- Refresh tag table after creating tags (createTags already does this with forceRefresh)
    end

    -- Step 3: Process each queued item
    for i, item in ipairs(_queue) do
        local callStatus = PiwigoAPI.updateMetadata(item.propertyTable, item.lrPhoto, item.metaData)
        if callStatus.status then
            results.success = results.success + 1
        else
            results.failed = results.failed + 1
            results.errors[#results.errors + 1] = callStatus.statusMsg or "Unknown error"
        end
    end

    log:info("MetadataBatcher.flush - completed: " .. results.success .. " success, " .. results.failed .. " failed")

    -- Clear the queue
    _queue = {}

    return results
end

-- *************************************************
-- Clear the queue without processing
-- *************************************************
function MetadataBatcher.clear()
    local count = #_queue
    _queue = {}
    log:info("MetadataBatcher.clear - cleared " .. count .. " items")
    return count
end

-- *************************************************
-- Set batch size
-- *************************************************
function MetadataBatcher.setBatchSize(size)
    BATCH_SIZE = size or 10
end

-- *************************************************
-- Get batch size
-- *************************************************
function MetadataBatcher.getBatchSize()
    return BATCH_SIZE
end

return MetadataBatcher
