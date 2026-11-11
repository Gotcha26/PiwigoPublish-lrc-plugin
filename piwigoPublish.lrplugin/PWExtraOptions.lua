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

require "UIHelpers"

-- *************************************************
-- Define a value_equal function for the popup_menu
local function valueEqual(a, b)
    return a == b
end

-- *************************************************
local function setAlbumCoverFromSelection(service)
    log:info("PWExtraOptions.setAlbumCoverFromSelection")

    local catalog = LrApplication.activeCatalog()
    local selPhotos = catalog:getTargetPhotos()
    local sources = catalog:getActiveSources()

    if utils.nilOrEmpty(selPhotos) then
        LrDialogs.message("Please select a photo to set as album cover", "", "warning")
        return false
    end
    if #selPhotos > 1 then
        LrDialogs.message("Please select a single photo to set as album cover (" .. #selPhotos .. " currently selected)",
            "", "warning")
        return false
    end

    local selPhoto = selPhotos[1]
    local useSource = nil

    for _, source in pairs(sources or {}) do
        if type(source) == "table" and source.type then
            local srcType = source:type()
            if srcType == "LrPublishedCollection" or srcType == "LrPublishedCollectionSet" then
                local thisService = source:getService()
                if thisService and thisService.localIdentifier == service.localIdentifier then
                    useSource = source
                    break
                end
            end
        end
    end

    if not useSource then
        LrDialogs.message("Please select a photo in a collection from the selected Piwigo Publisher service", "",
            "warning")
        return false
    end

    local publishSettings = service:getPublishSettings()
    local catId = useSource:getRemoteId()
    if not catId then
        LrDialogs.message("SetAlbumCover - Can't find Piwigo album ID for remoteId for this publish collection", "",
            "warning")
        return false
    end

    local thisPubPhoto = utils.findPhotoInCollectionSet(useSource, selPhoto)
    if not thisPubPhoto then
        LrDialogs.message(
            "PWSetAlbumCover - Can't find this photo in collection set or collections - has it been published?", "",
            "warning")
        return false
    end

    local remoteId = thisPubPhoto:getRemoteId()
    if not remoteId or remoteId == "" then
        LrDialogs.message("PWSetAlbumCover - Can't find Piwigo photo ID for this photo - has it been published?", "",
            "warning")
        return false
    end

    local result = LrDialogs.confirm("Set Piwigo Album Cover",
        "Set selected photo as cover photo for " .. useSource:getName() .. "?", "Ok", "Cancel")
    if result ~= 'ok' then
        return false
    end

    if not publishSettings.Connected then
        local rv = PiwigoAPI.login(publishSettings)
        if not rv then
            LrDialogs.message("SetAlbumCover - cannot connect to Piwigo")
            return false
        end
    end

    if publishSettings.userStatus ~= "webmaster" then
        LrDialogs.message("User needs webmaster role on Piwigo gallery at " ..
            publishSettings.host .. " to set album cover")
        return false
    end

    local params = {
        { name = "method",      value = "pwg.categories.setRepresentative" },
        { name = "category_id", value = catId },
        { name = "image_id",    value = remoteId },
    }
    local postResponse = PiwigoAPI.httpPostMultiPart(publishSettings, params)
    if not postResponse.status then
        LrDialogs.message("Unable to set cover photo - " .. postResponse.statusMsg)
        return false
    end

    return true
end

-- *************************************************
local function sendMetadataForSelection(service)
    log:info("PWExtraOptions.sendMetadataForSelection")

    local catalog = LrApplication.activeCatalog()
    local selPhotos = catalog:getTargetPhotos()
    local sources = catalog:getActiveSources()

    if utils.nilOrEmpty(selPhotos) then
        LrDialogs.message("Please select photos to resend metadata", "", "warning")
        return false
    end

    local useSource = nil
    for _, source in pairs(sources or {}) do
        if type(source) == "table" and source.type then
            local srcType = source:type()
            if srcType == "LrPublishedCollection" or srcType == "LrPublishedCollectionSet" then
                local thisService = source:getService()
                if thisService and thisService.localIdentifier == service.localIdentifier then
                    useSource = source
                    break
                end
            end
        end
    end

    if not useSource then
        LrDialogs.message("Please select photos in a collection from the selected Piwigo Publisher service", "", "warning")
        return false
    end

    local publishSettings = service:getPublishSettings()
    if not publishSettings then
        LrDialogs.message("SendMetadata - Can't find publish settings for this publish collection", "", "warning")
        return false
    end

    local result = LrDialogs.confirm("Send Metadata to Piwigo",
        "Send metadata to Piwigo for " .. #selPhotos .. " photo(s) in album " .. useSource:getName() .. "?", "Ok",
        "Cancel")
    if result ~= 'ok' then
        return false
    end

    local progressScope = LrProgressScope {
        title = "Update Metadata...",
        caption = "Starting...",
    }

    for pp, lrPhoto in pairs(selPhotos) do
        if progressScope:isCanceled() then
            break
        end
        progressScope:setPortionComplete(pp, #selPhotos)
        progressScope:setCaption("Processing " .. pp .. " of " .. #selPhotos .. " photographs")

        local thisPubPhoto = utils.findPhotoInCollectionSet(useSource, lrPhoto)
        if not thisPubPhoto then
            LrDialogs.message(
                "SendMetadata - Can't find this photo in collection set or collections - has it been published?", "",
                "warning")
            progressScope:done()
            return false
        end

        local remoteId = thisPubPhoto:getRemoteId()
        if not remoteId then
            LrDialogs.message("SendMetadata - Can't find Piwigo photo ID for this photo - has it been published?", "",
                "warning")
            progressScope:done()
            return false
        end

        local metaData = utils.getPhotoMetadata(publishSettings, lrPhoto, {})
        metaData.Remoteid = remoteId

        local callStatus = PiwigoAPI.updateMetadata(publishSettings, lrPhoto, metaData)
        if not callStatus.status then
            LrDialogs.message("Unable to set metadata for uploaded photo - " .. callStatus.statusMsg)
        end
    end

    progressScope:done()
    return true
end

-- *************************************************
local function convertSelectionCollectionToSet(publishService)
    log:info("PWExtraOptions.convertSelectionCollectionToSet")

    local catalog = LrApplication.activeCatalog()
    local sources = catalog:getActiveSources()

    local selectedCollection = nil
    for _, source in pairs(sources or {}) do
        if type(source) == "table" and source.type then
            local srcType = source:type()
            if srcType == "LrPublishedCollection" or srcType == "LrPublishedCollectionSet" then
                local thisService = source:getService()
                if thisService and thisService.localIdentifier == publishService.localIdentifier then
                    selectedCollection = source
                    break
                end
            end
        end
    end

    if not selectedCollection then
        LrDialogs.message("CollToSet - Can't access selected collection in the chosen service", "", "warning")
        return false
    end

    if selectedCollection:type() == "LrPublishedCollectionSet" then
        LrDialogs.message(
            "CollToSet - You selected a Published Collection Set. Please select a Published Collection.", "",
            "warning")
        return false
    end

    local publishSettings = publishService:getPublishSettings()
    if not publishSettings then
        LrDialogs.message("CollToSet - Can't find publish settings for this publish collection", "", "warning")
        return false
    end

    local selCollName = selectedCollection:getName()
    local selColParent = selectedCollection:getParent()
    local catId = selectedCollection:getRemoteId()

    if selColParent then
        if selCollName == PiwigoAPI.buildSpecialCollectionName(selColParent:getName()) then
            LrDialogs.message("Special collections cannot be converted to Collection Sets", "", "warning")
            return false
        end
    end

    local result = LrDialogs.confirm("Convert Published Collection to Set",
        "Convert " .. selCollName .. " to a Published Collection Set?", "Ok", "Cancel")
    if result ~= 'ok' then
        return false
    end
    local silent = false
    local newCollSet = utils.convertCollectionToSet(catalog, publishService, selectedCollection, silent)
    if newCollSet then
        return true
    end
    return false
    --[[
    local newName = PiwigoAPI.buildSpecialCollectionName(selCollName)
    local rv = PiwigoAPI.setCollectionDets(selectedCollection, catalog, publishSettings, newName, catId, selColParent)

    local newCollSet = PiwigoAPI.createPublishCollectionSet(catalog, publishService, publishSettings, selCollName, catId,
        selColParent)
    if not newCollSet then
        LrDialogs.message("CollToSet - Can't create new collection set " .. selCollName, "", "warning")
        return false
    end

    rv = PiwigoAPI.setCollectionDets(selectedCollection, catalog, publishSettings, newName, catId, newCollSet)
    ]]
end

-- *************************************************
-- Resync album with Piwigo (issue #9)
-- *************************************************
local function collectServiceCollections(node, out)
    -- recursive walk of a publish service / collection set, returns every LrPublishedCollection
    for _, coll in ipairs(node:getChildCollections() or {}) do
        table.insert(out, coll)
    end
    for _, set in ipairs(node:getChildCollectionSets() or {}) do
        collectServiceCollections(set, out)
    end
    return out
end

local function sampleList(items, maxItems)
    local lines = {}
    for i, item in ipairs(items) do
        if i > maxItems then
            table.insert(lines, "  ... (+" .. (#items - maxItems) .. " more)")
            break
        end
        table.insert(lines, "  " .. item)
    end
    return table.concat(lines, "\n")
end

-- forward declarations (defined after resyncAlbumWithPiwigo)
local removeExtraPhotos, fixMissingPhotos

local function resyncAlbumWithPiwigo(service)
    log:info("PWExtraOptions.resyncAlbumWithPiwigo")

    local catalog = LrApplication.activeCatalog()
    local sources = catalog:getActiveSources()

    -- 1. selected published collection in this service
    local useCollection = nil
    for _, source in pairs(sources or {}) do
        if type(source) == "table" and source.type and source:type() == "LrPublishedCollection" then
            local thisService = source:getService()
            if thisService and thisService.localIdentifier == service.localIdentifier then
                useCollection = source
                break
            end
        end
    end
    if not useCollection then
        LrDialogs.message("Resync Album",
            "Please select a published collection (not a collection set) in the selected Piwigo Publisher service.",
            "warning")
        return false
    end

    local catId = useCollection:getRemoteId()
    if utils.nilOrEmpty(catId) then
        LrDialogs.message("Resync Album", "Selected collection has no linked Piwigo album (missing remote ID).",
            "warning")
        return false
    end
    catId = tostring(catId)
    local collName = useCollection:getName()

    local publishSettings = service:getPublishSettings()
    if not publishSettings then
        LrDialogs.message("Resync Album", "Cannot read publish settings for the selected service.", "warning")
        return false
    end

    local serviceState = PWStatusManager.getServiceState(service)
    if serviceState.PiwigoBusy then
        utils.pwBusyMessage("PWExtraOptions.resyncAlbumWithPiwigo", "Resync Album")
        return false
    end

    if not publishSettings.Connected then
        if not PiwigoAPI.login(publishSettings) then
            LrDialogs.message("Resync Album", "Cannot connect to Piwigo at " .. tostring(publishSettings.host),
                "warning")
            return false
        end
    end
    if publishSettings.userStatus ~= "webmaster" then
        LrDialogs.message("Resync Album", "User needs webmaster role on Piwigo gallery at " ..
            tostring(publishSettings.host), "warning")
        return false
    end

    local progressScope = LrProgressScope { title = "Resync album " .. collName, caption = "Reading Piwigo album..." }

    -- 2. Piwigo side
    local pwResult = PiwigoAPI.getCategoryImages(publishSettings, catId)
    if not pwResult.status then
        progressScope:done()
        LrDialogs.message("Resync Album", "Cannot list photos of Piwigo album " .. catId .. " - " ..
            tostring(pwResult.statusMsg), "warning")
        return false
    end

    -- the admin count is not filtered by privacy level: warn if the listing looks incomplete
    local adminCount = nil
    local catInfo = PiwigoAPI.pwCategoriesGetThis(publishSettings, catId)
    if catInfo and catInfo.nb_images then
        adminCount = tonumber(catInfo.nb_images)
    end

    -- 3. Lightroom side: remote ids of every collection of this service linked to the same album
    progressScope:setCaption("Reading Lightroom collections...")
    local lrIds = {}
    local lrCount = 0
    for _, coll in ipairs(collectServiceCollections(service, {})) do
        if tostring(coll:getRemoteId() or "") == catId then
            for _, pubPhoto in ipairs(coll:getPublishedPhotos() or {}) do
                local rid = pubPhoto:getRemoteId()
                if not utils.nilOrEmpty(rid) and not lrIds[tostring(rid)] then
                    lrIds[tostring(rid)] = pubPhoto
                    lrCount = lrCount + 1
                end
            end
        end
    end

    -- 4. index LrC photos by the Piwigo image id stored in their plugin metadata (pwImageURL)
    progressScope:setCaption("Matching Piwigo images to Lightroom photos...")
    local lrPhotoByPwId = {}
    local withUrl = catalog:findPhotosWithProperty(_PLUGIN.id, "pwImageURL") or {}
    if #withUrl > 0 then
        local props = catalog:batchGetPropertyForPlugin(withUrl, _PLUGIN.id, { "pwImageURL" }) or {}
        for _, lrPhoto in ipairs(withUrl) do
            local p = props[lrPhoto]
            local pwId = p and utils.extractPwImageIdFromUrl(p.pwImageURL, publishSettings.host)
            if pwId then
                lrPhotoByPwId[pwId] = lrPhoto
            end
        end
    end

    -- 5. compare
    local pwIds = {}
    local extraKnown, extraUnknown = {}, {}
    for _, img in ipairs(pwResult.images) do
        pwIds[img.id] = true
        if not lrIds[img.id] then
            local entry = { id = img.id, file = img.file, lrPhoto = lrPhotoByPwId[img.id] }
            if entry.lrPhoto then
                table.insert(extraKnown, entry)
            else
                table.insert(extraUnknown, entry)
            end
        end
    end
    local missing = {}
    for rid, pubPhoto in pairs(lrIds) do
        if not pwIds[rid] then
            table.insert(missing, {
                id = rid,
                pubPhoto = pubPhoto,
                label = (pubPhoto:getPhoto():getFormattedMetadata("fileName") or "?") .. " (id " .. rid .. ")",
            })
        end
    end
    progressScope:done()

    log:info(string.format("PWExtraOptions.resync - album %s (%s): piwigo=%d, admin count=%s, lightroom=%d, " ..
        "extra known=%d, extra unknown=%d, missing on piwigo=%d", catId, collName, #pwResult.images,
        tostring(adminCount), lrCount, #extraKnown, #extraUnknown, #missing))
    for _, e in ipairs(extraKnown) do
        log:info("PWExtraOptions.resync - extra (from Lightroom) id " .. e.id .. " " .. e.file)
    end
    for _, e in ipairs(extraUnknown) do
        log:info("PWExtraOptions.resync - extra (unknown origin) id " .. e.id .. " " .. e.file)
    end
    for _, m in ipairs(missing) do
        log:info("PWExtraOptions.resync - missing on piwigo: " .. m.label)
    end

    -- 6. summary
    local header = string.format("Piwigo album: %d photo(s)    Lightroom collection: %d photo(s)",
        #pwResult.images, lrCount)
    if adminCount and adminCount ~= #pwResult.images then
        header = header .. string.format(
            "\nWARNING: Piwigo reports %d photo(s) in this album but only %d are visible to this account " ..
            "(privacy level?). Hidden photos are not checked.", adminCount, #pwResult.images)
    end

    if #extraKnown == 0 and #extraUnknown == 0 and #missing == 0 then
        LrDialogs.message("Resync Album - " .. collName, "Album and collection are in sync.\n\n" .. header, "info")
        return true
    end

    local reports = {}
    local allOk = true

    -- 7. photos on Piwigo that are no longer in the collection: remove them
    if #extraKnown > 0 or #extraUnknown > 0 then
        local ok, report = removeExtraPhotos(publishSettings, catalog, service, useCollection, collName, catId,
            header, extraKnown, extraUnknown)
        if report then table.insert(reports, report) end
        allOk = allOk and ok
    end

    -- 8. photos of the collection that are no longer in the Piwigo album: re-add or republish them (issue #10)
    if #missing > 0 then
        local ok, report = fixMissingPhotos(publishSettings, catalog, service, collName, catId, header, missing)
        if report then table.insert(reports, report) end
        allOk = allOk and ok
    end

    if #reports > 0 then
        LrDialogs.message("Resync Album - " .. collName, table.concat(reports, "\n\n"), allOk and "info" or "warning")
    end
    return allOk
end

-- *************************************************
-- Step 7: remove photos left on Piwigo. Returns ok, report (report nil if cancelled)
removeExtraPhotos = function(publishSettings, catalog, service, useCollection, collName, catId, header,
                             extraKnown, extraUnknown)
    local summary = { header }

    local knownNames, unknownNames = {}, {}
    for _, e in ipairs(extraKnown) do
        table.insert(knownNames, e.file .. " (id " .. e.id .. ")")
    end
    for _, e in ipairs(extraUnknown) do
        table.insert(unknownNames, e.file .. " (id " .. e.id .. ")")
    end
    if #extraKnown > 0 then
        table.insert(summary, string.format(
            "\n%d photo(s) on Piwigo come from Lightroom but are no longer in this collection:\n%s",
            #extraKnown, sampleList(knownNames, 8)))
    end
    if #extraUnknown > 0 then
        table.insert(summary, string.format(
            "\n%d photo(s) on Piwigo have no known Lightroom origin (e.g. uploaded from the web):\n%s",
            #extraUnknown, sampleList(unknownNames, 8)))
    end
    table.insert(summary,
        "\nRemoving a photo takes it out of this album; it is deleted from Piwigo only if it is in no other album.")

    local actionVerb = (#extraKnown > 0) and ("Remove " .. #extraKnown .. " Lightroom photo(s)") or nil
    local otherVerb = (#extraUnknown > 0) and ("Remove all " .. (#extraKnown + #extraUnknown) .. " photo(s)") or nil
    if not actionVerb then
        actionVerb, otherVerb = otherVerb, nil
    end

    local choice = LrDialogs.confirm("Resync Album - " .. collName, table.concat(summary, "\n"), actionVerb,
        "Skip", otherVerb)
    if choice == "cancel" then
        return true, nil
    end

    local toRemove = {}
    for _, e in ipairs(extraKnown) do table.insert(toRemove, e) end
    if choice == "other" or #extraKnown == 0 then
        for _, e in ipairs(extraUnknown) do table.insert(toRemove, e) end
    end

    -- 7. remove
    PWStatusManager.setPiwigoBusy(service, true)
    local removed, deleted, failed = 0, 0, {}
    local ok, err = LrTasks.pcall(function()
        local scope = LrProgressScope { title = "Resync album " .. collName, caption = "Removing photos..." }
        for i, e in ipairs(toRemove) do
            if scope:isCanceled() then break end
            scope:setPortionComplete(i - 1, #toRemove)
            scope:setCaption("Removing " .. i .. " of " .. #toRemove .. " - " .. e.file)

            local callStatus = PiwigoAPI.removeImageFromCategory(publishSettings, e.id, catId)
            if callStatus.status then
                removed = removed + 1
                log:info("PWExtraOptions.resync - removed id " .. e.id .. " from album " .. catId ..
                    (callStatus.deletedImage and " (deleted from Piwigo)" or " (kept in other albums)"))
                if callStatus.deletedImage then
                    deleted = deleted + 1
                    if e.lrPhoto then
                        utils.refreshPwMetadataAfterRemoval(catalog, service, e.lrPhoto, useCollection)
                    end
                end
            else
                log:info("PWExtraOptions.resync - FAILED id " .. e.id .. ": " .. tostring(callStatus.statusMsg))
                table.insert(failed, e.file .. " (id " .. e.id .. "): " .. tostring(callStatus.statusMsg))
            end
        end
        scope:done()
    end)
    PWStatusManager.setPiwigoBusy(service, false)

    local report = string.format("%d photo(s) removed from the album, %d of them deleted from Piwigo.",
        removed, deleted)
    if #failed > 0 then
        report = report .. string.format("\n%d removal failure(s) - run Resync again to retry:\n%s", #failed,
            sampleList(failed, 8))
    end
    if not ok then
        report = report .. "\nUnexpected error: " .. tostring(err)
    end
    return ok and #failed == 0, report
end

-- *************************************************
-- Step 8: photos of the collection missing from the Piwigo album (issue #10).
--   - image still on Piwigo (in other albums): re-add it to this album, the Piwigo ID is kept
--   - image deleted from Piwigo: mark the photo to republish (it will be uploaded with a NEW ID)
-- Returns ok, report (report nil if cancelled)
fixMissingPhotos = function(publishSettings, catalog, service, collName, catId, header, missing)
    local toReattach, toRepublish, inAlbum, unknown = {}, {}, {}, {}

    local scope = LrProgressScope { title = "Resync album " .. collName, caption = "Checking missing photos..." }
    for i, m in ipairs(missing) do
        scope:setPortionComplete(i - 1, #missing)
        local check = PiwigoAPI.checkPhoto(publishSettings, m.id)
        if check.status then
            local inThisAlbum = false
            for _, cat in ipairs((check.imageDets and check.imageDets.categories) or {}) do
                if tostring(cat.id) == catId then inThisAlbum = true end
            end
            if inThisAlbum then
                -- associated to the album but not listed (privacy level): nothing to fix
                table.insert(inAlbum, m)
            else
                table.insert(toReattach, m)
            end
        elseif PiwigoAPI.isImageNotFound(check) then
            table.insert(toRepublish, m)
        else
            m.error = tostring(check.httpStatusDes)
            table.insert(unknown, m)
        end
    end
    scope:done()

    local function labels(list)
        local out = {}
        for _, m in ipairs(list) do table.insert(out, m.label) end
        return out
    end
    for _, m in ipairs(toReattach) do log:info("PWExtraOptions.resync - missing, still on Piwigo: " .. m.label) end
    for _, m in ipairs(toRepublish) do log:info("PWExtraOptions.resync - missing, deleted from Piwigo: " .. m.label) end
    for _, m in ipairs(inAlbum) do log:info("PWExtraOptions.resync - missing, but in album (hidden): " .. m.label) end
    for _, m in ipairs(unknown) do
        log:info("PWExtraOptions.resync - missing, cannot check: " .. m.label .. " - " .. m.error)
    end

    local notes = {}
    if #inAlbum > 0 then
        table.insert(notes, string.format("%d photo(s) are in the album but hidden from this account " ..
            "(privacy level) - nothing to do.", #inAlbum))
    end
    if #unknown > 0 then
        table.insert(notes, string.format("%d photo(s) could not be checked (see log):\n%s", #unknown,
            sampleList(labels(unknown), 5)))
    end

    if #toReattach == 0 and #toRepublish == 0 then
        return #unknown == 0, table.concat(notes, "\n")
    end

    local summary = { header, string.format("\n%d photo(s) of the collection are no longer in the Piwigo album.",
        #missing) }
    if #toReattach > 0 then
        table.insert(summary, string.format(
            "\n%d photo(s) still exist on Piwigo (in other albums). They will be added back to this album " ..
            "and keep their Piwigo ID:\n%s", #toReattach, sampleList(labels(toReattach), 6)))
    end
    if #toRepublish > 0 then
        table.insert(summary, string.format(
            "\n%d photo(s) were deleted from Piwigo. They will be marked to republish: at the next publish " ..
            "they are uploaded again with a NEW Piwigo ID (links, comments and favorites of the old image " ..
            "cannot be recovered):\n%s", #toRepublish, sampleList(labels(toRepublish), 6)))
    end
    for _, n in ipairs(notes) do table.insert(summary, "\n" .. n) end

    local choice = LrDialogs.confirm("Resync Album - " .. collName .. " - missing photos",
        table.concat(summary, "\n"), "Fix " .. (#toReattach + #toRepublish) .. " photo(s)", "Skip")
    if choice ~= "ok" then
        return true, nil
    end

    local reattached, marked, failed = 0, 0, {}
    PWStatusManager.setPiwigoBusy(service, true)
    local ok, err = LrTasks.pcall(function()
        local fixScope = LrProgressScope { title = "Resync album " .. collName, caption = "Adding photos back..." }
        for i, m in ipairs(toReattach) do
            if fixScope:isCanceled() then break end
            fixScope:setPortionComplete(i - 1, #toReattach)
            local callStatus = PiwigoAPI.withTokenRetry(publishSettings, "re-add image " .. m.id, function()
                return PiwigoAPI.associateImageToCategory(publishSettings, m.id, catId)
            end)
            if callStatus.status then
                reattached = reattached + 1
                log:info("PWExtraOptions.resync - re-added id " .. m.id .. " to album " .. catId)
            else
                log:info("PWExtraOptions.resync - FAILED to re-add id " .. m.id .. ": " ..
                    tostring(callStatus.statusMsg))
                table.insert(failed, m.label .. ": " .. tostring(callStatus.statusMsg))
            end
        end
        fixScope:done()

        if #toRepublish > 0 then
            catalog:withWriteAccessDo("Mark photos to republish", function()
                for _, m in ipairs(toRepublish) do
                    m.pubPhoto:setEditedFlag(true)
                    marked = marked + 1
                    log:info("PWExtraOptions.resync - marked to republish: " .. m.label)
                end
            end)
        end
    end)
    PWStatusManager.setPiwigoBusy(service, false)

    local lines = {}
    if #toReattach > 0 then
        table.insert(lines, string.format("%d photo(s) added back to the album (Piwigo ID kept).", reattached))
    end
    if #toRepublish > 0 then
        table.insert(lines, string.format("%d photo(s) marked to republish - click Publish to upload them again.",
            marked))
    end
    if #failed > 0 then
        table.insert(lines, string.format("%d failure(s) - run Resync again to retry:\n%s", #failed,
            sampleList(failed, 6)))
    end
    if not ok then
        table.insert(lines, "Unexpected error: " .. tostring(err))
    end
    for _, n in ipairs(notes) do table.insert(lines, n) end
    return ok and #failed == 0 and #unknown == 0, table.concat(lines, "\n")
end

-- *************************************************
local function syncCurrentAlbumSortNow(service)
    log:info("PWExtraOptions.syncCurrentAlbumSortNow")

    local catalog = LrApplication.activeCatalog()
    local sources = catalog:getActiveSources()

    local useCollection = nil
    local publishSettings = service and service:getPublishSettings() or nil

    for _, source in pairs(sources or {}) do
        if type(source) == "table" and source.type and source:type() == "LrPublishedCollection" then
            local thisService = source:getService()
            if thisService and thisService.localIdentifier == service.localIdentifier then
                useCollection = source
                break
            end
        end
    end

    if not useCollection then
        LrDialogs.message("Please select a published collection in the selected Piwigo Publisher service.", "", "warning")
        return false
    end

    local categoryId = useCollection:getRemoteId()
    if utils.nilOrEmpty(categoryId) then
        LrDialogs.message("Selected collection has no linked Piwigo album (missing remote ID).", "", "warning")
        return false
    end

    if not publishSettings then
        LrDialogs.message("Cannot read publish settings for the selected collection.", "", "warning")
        return false
    end

    local publishedPhotos = useCollection:getPublishedPhotos() or {}
    if #publishedPhotos == 0 then
        LrDialogs.message("Selected collection has no published photos to sync.", "", "warning")
        return false
    end

    local imageIdSequence = {}
    for _, pubPhoto in ipairs(publishedPhotos) do
        local remoteId = pubPhoto:getRemoteId()
        if not utils.nilOrEmpty(remoteId) then
            table.insert(imageIdSequence, tostring(remoteId))
        end
    end

    if #imageIdSequence == 0 then
        LrDialogs.message("No publishable remote photo IDs were found in the selected collection.", "", "warning")
        return false
    end

    local result = LrDialogs.confirm(
        "Sync Current Album Sort Now",
        "Sync the current Lightroom order for " .. tostring(#imageIdSequence) .. " photo(s) to Piwigo album \"" ..
        useCollection:getName() .. "\"?",
        "Sync",
        "Cancel"
    )

    if result ~= "ok" then
        return false
    end

    local serverPluginAvailable = PiwigoAPI.hasPiwigoPublishServerPlugin(publishSettings, false)
    if not serverPluginAvailable then
        LrDialogs.message(
            "Piwigo server plugin unavailable",
            "The server method pwg.categories.setSortOrder is unavailable.\n" ..
            "Set album sort order manually in Piwigo (Album -> Edit -> Sort order: Manual).",
            "warning"
        )
    end

    if serverPluginAvailable then
        local orderStatus = PiwigoAPI.pwCategoriesSetSortOrder(publishSettings, categoryId, "rank ASC")
        if not orderStatus.status then
            LrDialogs.message("Unable to set album sort mode on Piwigo", orderStatus.statusMsg or "Unknown error",
                "warning")
            return false
        end
    end
    log:info("PWExtraOptions.syncCurrentAlbumSortNow - syncing sort order for category " ..
        tostring(categoryId) .. ", " .. #imageIdSequence .. " photos")
    log:info("Sort order is " .. utils.serialiseVar(imageIdSequence))
    local rankStatus = PiwigoAPI.pwImagesSetRank(publishSettings, categoryId, imageIdSequence)
    if not rankStatus.status then
        LrDialogs.message("Unable to sync current album order to Piwigo", rankStatus.statusMsg or "Unknown error",
            "warning")
        return false
    end

    LrDialogs.message(
        "Album Sort Synced",
        "Synced current Lightroom order for " .. tostring(#imageIdSequence) .. " photo(s) to Piwigo album \"" ..
        useCollection:getName() .. "\".",
        "info"
    )
    return true
end

-- *************************************************
-- Check image formats on Piwigo (issue #14)
-- *************************************************
local function checkImageFormats(service)
    -- Finds photos published by THIS service whose file on Piwigo kept an old extension
    -- after a republish in another format, and asks the companion to align them.
    log:info("PWExtraOptions.checkImageFormats")
    local title = "Check Image Formats"

    local publishSettings = service:getPublishSettings()
    if not publishSettings then
        LrDialogs.message(title, "Cannot read publish settings for the selected service.", "warning")
        return false
    end

    local serviceState = PWStatusManager.getServiceState(service)
    if serviceState.PiwigoBusy then
        utils.pwBusyMessage("PWExtraOptions.checkImageFormats", title)
        return false
    end

    if not publishSettings.Connected then
        if not PiwigoAPI.login(publishSettings) then
            LrDialogs.message(title, "Cannot connect to Piwigo at " .. tostring(publishSettings.host), "warning")
            return false
        end
    end
    if publishSettings.userStatus ~= "webmaster" then
        LrDialogs.message(title, "User needs webmaster role on Piwigo gallery at " ..
            tostring(publishSettings.host), "warning")
        return false
    end

    -- fresh check, never a cache left over by an earlier publish
    publishSettings._formatAlignSupport = nil
    if not PiwigoAPI.getFormatAlignSupport(publishSettings) then
        LrDialogs.message(title,
            "This needs the Lightroom Companion plugin (Free edition is enough) installed and active on your Piwigo server.",
            "warning")
        return false
    end

    -- only the photos published by this service (never web uploads or other services)
    local ids, seen = {}, {}
    for _, coll in ipairs(collectServiceCollections(service, {})) do
        for _, pubPhoto in ipairs(coll:getPublishedPhotos() or {}) do
            local remoteId = pubPhoto:getRemoteId()
            if not utils.nilOrEmpty(remoteId) and not seen[tostring(remoteId)] then
                seen[tostring(remoteId)] = true
                table.insert(ids, tostring(remoteId))
            end
        end
    end
    if #ids == 0 then
        LrDialogs.message(title, "The selected service has no published photos.", "info")
        return false
    end

    local listStatus = PiwigoAPI.listFormatMismatches(publishSettings, ids)
    if not listStatus.status then
        LrDialogs.message(title, "Cannot read image formats from Piwigo - " .. tostring(listStatus.statusMsg), "warning")
        return false
    end
    local mismatches = listStatus.images
    if #mismatches == 0 then
        LrDialogs.message(title, "All published photos are consistent.", "info")
        return true
    end

    local samples = {}
    for _, img in ipairs(mismatches) do
        table.insert(samples, tostring(img.file) .. "  (" .. tostring(img.path) .. ")")
    end
    local answer = LrDialogs.confirm(title,
        #mismatches .. " published photo(s) have a file extension that no longer matches their format.\n\n" ..
        sampleList(samples, 10),
        "Align all", "Cancel")
    if answer ~= "ok" then
        return false
    end

    local aligned, already, failed = 0, 0, 0
    local scope = LrProgressScope { title = "Aligning image formats" }
    scope:setCancelable(true)
    for i, img in ipairs(mismatches) do
        if scope:isCanceled() then break end
        scope:setPortionComplete(i - 1, #mismatches)
        scope:setCaption(tostring(img.file))
        local alignStatus = PiwigoAPI.alignImageFormat(publishSettings, img.id)
        if alignStatus.status and alignStatus.aligned then
            aligned = aligned + 1
        elseif alignStatus.status and alignStatus.reason == "already" then
            already = already + 1
        else
            failed = failed + 1
            log:info("PWExtraOptions.checkImageFormats - image " .. tostring(img.id) .. " not aligned: " ..
                tostring(alignStatus.statusMsg) .. " / " .. tostring(alignStatus.reason))
        end
    end
    local canceled = scope:isCanceled()
    scope:done()

    LrDialogs.message(title,
        (canceled and "Canceled.\n\n" or "") ..
        "Aligned: " .. aligned .. "\nAlready consistent: " .. already .. "\nFailed: " .. failed ..
        (failed > 0 and "\n\nReasons are in the plug-in log file." or ""),
        failed > 0 and "warning" or "info")
    return failed == 0
end

-- *************************************************
local function main()
    local share = LrView.share
    LrFunctionContext.callWithContext("PWExtraOptionsContext", function(context)
        log:info("PWExtraOptions")

        local allServices = PiwigoAPI.getPublishServicesForPlugin(_PLUGIN.id)
        if #allServices == 0 then
            LrDialogs.message("No Piwigo publish services found.")
            return
        end

        local serviceItems = {}
        local serviceNames = {}
        for i, s in ipairs(allServices) do
            table.insert(serviceItems, {
                title = s:getName(),
                value = s,
            })
            table.insert(serviceNames, {
                title = s:getName(),
                value = i,
            })
        end

        local props = LrBinding.makePropertyTable(context)
        props.selectedService = 1

        local f = LrView.osFactory()
        local c = f:column {
            spacing = f:dialog_spacing(),

            UIHelpers.createPluginHeader(f, share, iconPath, pluginVersion),

            f:row {
                spacing = f:label_spacing(),

                f:static_text {
                    title = "Select publish service:",
                    alignment = 'right',
                    width = 150,
                },

                f:popup_menu {
                    value = LrView.bind { key = 'selectedService', bind_to_object = props },
                    items = serviceNames,
                    value_equal = valueEqual,
                    width = 300,
                },
            },

            f:spacer { height = 20 },
            f:row {
                f:static_text {
                    title = "Applies to selected photos/collection",
                    font = "<system/bold>",
                    alignment = 'left',
                    fill_horizontal = 1,
                },
            },

            f:spacer { height = 4 },

            f:spacer { height = 1 },
            f:row {
                f:push_button {
                    title = 'Set Piwigo Album Cover',
                    tooltip = "Sets selected image as Piwigo album cover",
                    width = share 'buttonwidth',
                    action = function()
                        LrTasks.startAsyncTask(function()
                            local serviceNo = props.selectedService
                            local service = serviceItems[serviceNo] and serviceItems[serviceNo].value or nil
                            if not service then
                                LrDialogs.message("Error", "Could not find publish service", "error")
                                return
                            end
                            setAlbumCoverFromSelection(service)
                        end)
                    end,
                },
                f:static_text {
                    title = "Sets selected image as Piwigo album cover for the selected service",
                    alignment = 'left',
                    width_in_chars = 58,
                },
            },

            f:spacer { height = 1 },
            f:row {
                f:push_button {
                    title = 'Send Metadata to Piwigo',
                    tooltip = "Sends metadata for selected photos to Piwigo",
                    width = share 'buttonwidth',
                    action = function()
                        LrTasks.startAsyncTask(function()
                            local serviceNo = props.selectedService
                            local service = serviceItems[serviceNo] and serviceItems[serviceNo].value or nil
                            if not service then
                                LrDialogs.message("Error", "Could not find publish service", "error")
                                return
                            end
                            sendMetadataForSelection(service)
                        end)
                    end,
                },
                f:static_text {
                    title = "Sends metadata for selected photos in the selected service",
                    alignment = 'left',
                    width_in_chars = 58,
                },
            },

            f:spacer { height = 1 },
            f:row {
                f:push_button {
                    title = 'Convert Collection to Collection Set',
                    tooltip = "Converts selected published collection to a collection set",
                    width = share 'buttonwidth',
                    action = function()
                        LrTasks.startAsyncTask(function()
                            local serviceNo = props.selectedService
                            local service = serviceItems[serviceNo] and serviceItems[serviceNo].value or nil
                            if not service then
                                LrDialogs.message("Error", "Could not find publish service", "error")
                                return
                            end
                            convertSelectionCollectionToSet(service)
                        end)
                    end,
                },
                f:static_text {
                    title = "Converts selected published collection to a collection set",
                    alignment = 'left',
                    width_in_chars = 58,
                },
            },

            f:spacer { height = 1 },
            f:row {
                f:push_button {
                    title = 'Resync Album with Piwigo',
                    tooltip = "Compares the selected published collection with its Piwigo album: removes photos " ..
                        "left on Piwigo, adds back or marks to republish photos missing from the album",
                    width = share 'buttonwidth',
                    action = function()
                        LrTasks.startAsyncTask(function()
                            local serviceNo = props.selectedService
                            local service = serviceItems[serviceNo] and serviceItems[serviceNo].value or nil
                            if not service then
                                LrDialogs.message("Error", "Could not find publish service", "error")
                                return
                            end
                            resyncAlbumWithPiwigo(service)
                        end)
                    end,
                },
                f:static_text {
                    title = "Fixes differences between the selected collection and its Piwigo album",
                    alignment = 'left',
                    width_in_chars = 58,
                },
            },

            f:spacer { height = 20 },
            f:row {
                f:static_text {
                    title = "Applies to the whole selected service",
                    font = "<system/bold>",
                    alignment = 'left',
                    fill_horizontal = 1,
                },
            },

            f:spacer { height = 4 },
            f:row {
                f:push_button {
                    title = 'Check Image Formats on Piwigo',
                    tooltip = "Finds photos of the selected service whose file on Piwigo kept an old extension " ..
                        "after a format change (e.g. PNG to JPEG), and fixes them. Needs the Lightroom Companion plugin.",
                    width = share 'buttonwidth',
                    action = function()
                        LrTasks.startAsyncTask(function()
                            local serviceNo = props.selectedService
                            local service = serviceItems[serviceNo] and serviceItems[serviceNo].value or nil
                            if not service then
                                LrDialogs.message("Error", "Could not find publish service", "error")
                                return
                            end
                            checkImageFormats(service)
                        end)
                    end,
                },
                f:static_text {
                    title = "Finds and fixes photos of the selected service whose file kept an old extension",
                    alignment = 'left',
                    width_in_chars = 58,
                },
            },
            --[[
-- currently commented out as LrC SDK doesn't expose current display order of photos in a published collection
-- will be revisited
            f:spacer { height = 1 },
            f:row {
                f:push_button {
                    title = 'Sync Current Album Sort Now',
                    tooltip = "Sends the current Lightroom order for selected published collection to Piwigo",
                    action = function()
                        LrTasks.startAsyncTask(function()
                            local serviceNo = props.selectedService
                            local service = serviceItems[serviceNo] and serviceItems[serviceNo].value or nil
                            if not service then
                                LrDialogs.message("Error", "Could not find publish service", "error")
                                return
                            end
                            syncCurrentAlbumSortNow(service)
                        end)
                    end,
                },
                f:static_text {
                    title = "Syncs selected published collection's current order to Piwigo",
                    alignment = 'left',
                    width_in_chars = 58,
                },
            },
            ]]
        }

        LrDialogs.presentModalDialog {
            title = "Piwigo Publisher Extra Options",
            contents = c,
            actionVerb = "Close",
            cancelVerb = "< exclude >",
        }
    end)
end

-- *************************************************
-- Run main()
LrTasks.startAsyncTask(main)
