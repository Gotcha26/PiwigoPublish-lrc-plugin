--[[

    PublishTaskImageProcessing.lua

    Publish Tasks for image processing for Piwigo Publisher plugin

    Copyright (C) 2026 Fiona Boston <fiona@fbphotography.uk>.

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

PublishTaskImageProcessing = {}

-- ************************************************
local function cloneTable(source)
    local copy = {}
    for k, v in pairs(source) do
        copy[k] = v
    end
    return copy
end

-- ************************************************
local function resolveSourceSettings(propertyTable)
    local sourceSettings = propertyTable
    if type(propertyTable) == "table" and type(propertyTable["< contents >"]) == "table" then
        sourceSettings = propertyTable["< contents >"]
        log:info("runCustomRenderForCollection - using propertyTable['< contents >'] as export settings source")
    end
    return sourceSettings
end

-- ************************************************
local function buildCustomOverrideSettings(sourceSettings, collectionSettings)
    local overrideSettings = cloneTable(sourceSettings)

    if collectionSettings.reSize then
        local resizeParam = collectionSettings.reSizeParam or "Long Edge"
        overrideSettings.LR_size_doConstrain = true
        overrideSettings.LR_size_userWantsConstrain = true
        overrideSettings.LR_size_doNotEnlarge = collectionSettings.reSizeNoEnlarge and true or false
        overrideSettings.LR_size_dontEnlarge = nil
        overrideSettings.LR_size_percentage = nil

        if resizeParam == "Long Edge" then
            local edge = utils.toPositiveNumber(collectionSettings.reSizeLongEdge)
            if edge then
                overrideSettings.LR_size_maxHeight = edge
                overrideSettings.LR_size_maxWidth = edge
                overrideSettings.LR_size_maxH = nil
                overrideSettings.LR_size_maxW = nil
                overrideSettings.LR_size_resizeType = 'longEdge'
                overrideSettings.LR_size_units = 'pixels'
            else
                overrideSettings.LR_size_doConstrain = false
            end
        elseif resizeParam == "Short Edge" then
            local edge = utils.toPositiveNumber(collectionSettings.reSizeShortEdge)
            if edge then
                overrideSettings.LR_size_maxHeight = edge
                overrideSettings.LR_size_maxWidth = edge
                overrideSettings.LR_size_maxH = nil
                overrideSettings.LR_size_maxW = nil
                overrideSettings.LR_size_resizeType = 'shortEdge'
                overrideSettings.LR_size_units = 'pixels'
            else
                overrideSettings.LR_size_doConstrain = false
            end
        elseif resizeParam == "Dimensions" then
            local width = utils.toPositiveNumber(collectionSettings.reSizeW)
            local height = utils.toPositiveNumber(collectionSettings.reSizeH)
            if width and height then
                overrideSettings.LR_size_maxWidth = width
                overrideSettings.LR_size_maxHeight = height
                overrideSettings.LR_size_maxH = nil
                overrideSettings.LR_size_maxW = nil
                overrideSettings.LR_size_resizeType = 'wh'
                overrideSettings.LR_size_units = 'pixels'
            else
                overrideSettings.LR_size_doConstrain = false
            end
        elseif resizeParam == "MegaPixels" then
            local megaPixels = utils.toPositiveNumber(collectionSettings.reSizeMP)
            if megaPixels then
                overrideSettings.LR_size_maxWidth = megaPixels
                overrideSettings.LR_size_maxHeight = megaPixels
                overrideSettings.LR_size_maxH = nil
                overrideSettings.LR_size_maxW = nil
                overrideSettings.LR_size_resizeType = 'megapixels'
                overrideSettings.LR_size_units = 'pixels'
            else
                overrideSettings.LR_size_doConstrain = false
            end
        elseif resizeParam == "Percent" then
            local percent = utils.toPositiveNumber(collectionSettings.reSizePC)
            if percent then
                overrideSettings.LR_size_percentage = percent
                overrideSettings.LR_size_maxWidth = nil
                overrideSettings.LR_size_maxHeight = nil
                overrideSettings.LR_size_maxH = nil
                overrideSettings.LR_size_maxW = nil
                overrideSettings.LR_size_resizeType = 'wh'
                overrideSettings.LR_size_units = 'percent'
            else
                overrideSettings.LR_size_doConstrain = false
                overrideSettings.LR_size_userWantsConstrain = false
            end
        else
            overrideSettings.LR_size_doConstrain = false
            overrideSettings.LR_size_userWantsConstrain = false
        end
    else
        overrideSettings.LR_size_doConstrain = false
        overrideSettings.LR_size_userWantsConstrain = false
    end

    return overrideSettings
end

-- ************************************************
local function getCustomRenderDecision(propertyTable, collectionSettings)
    local sourceSettings = resolveSourceSettings(propertyTable)

    local customAlbumSettingsEnabled = false
    if propertyTable and propertyTable.PWP_customAlbumSettings then
        customAlbumSettingsEnabled = true
    elseif sourceSettings and sourceSettings.PWP_customAlbumSettings then
        customAlbumSettingsEnabled = true
    end


    local rtnStatus = {
        sourceSettings = sourceSettings,
        overrideSettings = sourceSettings,
        settingsDiffer = false,
        changedKey = nil,
        originalValue = nil,
        newValue = nil,
        customEnabled = false,
    }

    local customForThisCollectionEnabled = collectionSettings and collectionSettings.enableCustom

    if not (customAlbumSettingsEnabled and customForThisCollectionEnabled) then
        return rtnStatus
    end

    local overrideSettings = buildCustomOverrideSettings(sourceSettings, collectionSettings)
    local settingsDiffer, changedKey, originalValue, newValue = utils.resizeSettingsDiffer(sourceSettings,
        overrideSettings)

    rtnStatus.sourceSettings = sourceSettings
    rtnStatus.overrideSettings = overrideSettings
    rtnStatus.settingsDiffer = settingsDiffer
    rtnStatus.changedKey = changedKey
    rtnStatus.originalValue = originalValue
    rtnStatus.newValue = newValue
    rtnStatus.customEnabled = true

    return rtnStatus
end

-- ************************************************
local function createCustomRender(rendition, filePath, overrideSettings)
    local photoToRender = rendition.photo
    local customSession = LrExportSession {
        photosToExport = { photoToRender },
        exportSettings = overrideSettings,
    }

    for _, customRendition in customSession:renditions() do
        local customSuccess, customPath = customRendition:waitForRender()
        if customSuccess then
            LrFileUtils.delete(filePath)
            filePath = customPath
            log:info("Custom render successful, proceeding with upload using custom rendered file at path: " .. filePath)
        else
            rendition:uploadFailed(customPath)
        end
    end

    return filePath
end

-- ************************************************
local function runCustomRenderForCollection(customRenderInfo, collectionSettings, rendition, filePath)
    -- run custom render using precomputed custom render info

    utils.dumpPropertyTableToDesktop(customRenderInfo.sourceSettings, collectionSettings,
        "before custom resize overrides")
    log:info("Custom album export settings enabled, need to re-render photo with custom settings before upload")
    local anonSettings = utils.anonymisePropertyTable(cloneTable(customRenderInfo.sourceSettings))
    log:info("Property Table:\n" .. utils.serialiseVar(anonSettings))
    log:info("Collection Settings:\n" .. utils.serialiseVar(collectionSettings))

    anonSettings = utils.anonymisePropertyTable(cloneTable(customRenderInfo.overrideSettings))
    log:info("Override render settings:\n" .. utils.serialiseVar(anonSettings))

    local function resizeSnapshot(settings)
        return {
            LR_size_doConstrain = settings.LR_size_doConstrain,
            LR_size_userWantsConstrain = settings.LR_size_userWantsConstrain,
            LR_size_doNotEnlarge = settings.LR_size_doNotEnlarge ~= nil and settings.LR_size_doNotEnlarge or
                settings.LR_size_dontEnlarge,
            LR_size_maxWidth = settings.LR_size_maxWidth ~= nil and settings.LR_size_maxWidth or settings.LR_size_maxW,
            LR_size_maxHeight = settings.LR_size_maxHeight ~= nil and settings.LR_size_maxHeight or settings
                .LR_size_maxH,
            LR_size_percentage = settings.LR_size_percentage,
            LR_size_resizeType = settings.LR_size_resizeType,
            LR_size_units = settings.LR_size_units,
        }
    end

    log:info("Resize keys original/custom:\n" ..
        utils.serialiseVar({
            original = resizeSnapshot(customRenderInfo.sourceSettings),
            custom = resizeSnapshot(customRenderInfo.overrideSettings)
        }))

    if customRenderInfo.settingsDiffer then
        log:info("Custom settings differ from original render settings - re-render required")
        log:info("Changed key: " .. tostring(customRenderInfo.changedKey) .. ", original=" ..
            tostring(customRenderInfo.originalValue) ..
            ", custom=" .. tostring(customRenderInfo.newValue))

        filePath = createCustomRender(rendition, filePath, customRenderInfo.overrideSettings)
    else
        log:info("Custom settings match original render settings - skipping re-render")
    end

    return filePath
end

-- ************************************************
function PublishTaskImageProcessing.processRenderedPhotos(functionContext, exportContext)
    -- render photos and upload to Piwigo

    log:info("PublishTaskImageProcessing.processRenderedPhotos - version: " .. utils.serialiseVar(_PLUGIN.VERSION))
    local callStatus = {}
    local catalog = LrApplication.activeCatalog()
    local exportSession = exportContext.exportSession
    local propertyTable = exportContext.propertyTable

    local publishedCollection = exportContext.publishedCollection
    local publishService = publishedCollection:getService()
    local rv
    if not publishService then
        log:info('PublishTaskImageProcessing.processRenderedPhotos - propertyTable:\n' ..
            utils.serialiseVar(utils.anonymisePropertyTable(propertyTable)))
        LrErrors.throwUserError('Publish photos to Piwigo - cannot connect find publishService')
        return nil
    end

    local collectionInfo = publishedCollection:getCollectionInfoSummary()
    local collectionSettings = collectionInfo.collectionSettings or {}
    local collServiceState = {}
    local serviceState = {}
    if collectionSettings then
        collServiceState = collectionSettings.serviceState or {}
    end
    -- serviceState is a table containing publishService specific statusData
    if collServiceState then
        serviceState = collServiceState
    else
        serviceState = PWStatusManager.getServiceState(publishService)
    end
    log:info("PublishTaskImageProcessing.processRenderedPhotos - serviceState " .. utils.serialiseVar(serviceState))
    if serviceState.isCloningSync and serviceState.isCloningSync == true then
        PWStatusManager.setisCloningSync(publishService, false)
        -- use minimal render photos for smart collection cloning
        PublishTaskImageProcessing.processCloneSync(functionContext, exportContext)
        return
    end
    if serviceState.PiwigoBusy then
        return nil
    end
    PWStatusManager.setPiwigoBusy(publishService, true)

    -- Set progress title.
    local nPhotos = exportSession:countRenditions()
    local progressScope = exportContext:configureProgress {
        title = "Publishing " .. nPhotos .. " photos to " .. propertyTable.host
    }
    -- check connection to piwigo
    if not (propertyTable.Connected) then
        rv = PiwigoAPI.login(propertyTable)
        if not rv then
            log:info('PublishTaskImageProcessing.processRenderedPhotos - propertyTable:\n' ..
                utils.serialiseVar(utils.anonymisePropertyTable(propertyTable)))
            PWStatusManager.setPiwigoBusy(publishService, false)
            LrErrors.throwUserError('Publish photos to Piwigo - cannot connect to piwigo at ' .. propertyTable.host)
            return nil
        end
    end

    local parentCollSet = publishedCollection:getParent()
    local parentID = ""
    local albumName = publishedCollection:getName()
    -- check if album is special collection and and use name of parent album if so
    if string.sub(albumName, 1, 1) == "[" and string.sub(albumName, -1) == "]" then
        if parentCollSet then
            albumName = parentCollSet:getName()
        end
    end
    local albumId = publishedCollection:getRemoteId()
    local albumUrl = publishedCollection:getRemoteUrl()

    local requestRepub = false
    if parentCollSet then
        parentID = parentCollSet:getRemoteId()
    end
    local checkCats
    -- Check that collection exists as an album on Piwigo and create if not
    if albumId then
        rv, checkCats = PiwigoAPI.pwCategoriesGet(propertyTable, albumId)
        if not rv then
            PWStatusManager.setPiwigoBusy(publishService, false)
            LrErrors.throwUserError('Publish photos to Piwigo - cannot check category exists on piwigo at ' ..
                propertyTable.host)
            return nil
        end
    end

    if utils.nilOrEmpty(checkCats) or not (albumId) then
        -- create missing album on piwigo (may happen if album is deleted directly on Piwigo rather than via this plugin, or if smartcollectionimport is run)
        local metaData = {}
        callStatus = {}
        metaData.name = albumName
        metaData.parentCat = parentID
        callStatus = PiwigoAPI.pwCategoriesAdd(propertyTable, publishedCollection, metaData, callStatus)
        if callStatus.status then
            -- reset album id to newly created one
            albumId = callStatus.newCatId
            exportSession:recordRemoteCollectionId(albumId)
            exportSession:recordRemoteCollectionUrl(callStatus.albumURL)
            LrDialogs.message("*** Missing Piwigo album ***", albumName .. ", Piwigo Cat ID " .. albumId .. " created")
            requestRepub = true
        else
            PWStatusManager.setPiwigoBusy(publishService, false)
            LrErrors.throwUserError('Publish photos to Piwigo - cannot create Piwigo album for  ' .. albumName)
            return nil
        end
    end

    -- Keyword filter setup
    local kwFilterInclude = propertyTable.KwFilterInclude or ""
    local kwFilterExclude = propertyTable.KwFilterExclude or ""
    -- collection-level override if non-empty and albumAssoication disabled
    if not (propertyTable.PWP_albumAssociation) then
        if not utils.nilOrEmpty(collectionSettings.KwFilterInclude) then
            kwFilterInclude = collectionSettings.KwFilterInclude
        end
        if not utils.nilOrEmpty(collectionSettings.KwFilterExclude) then
            kwFilterExclude = collectionSettings.KwFilterExclude
        end
    end
    local includePatterns = utils.parseFilterPatterns(kwFilterInclude)
    local excludePatterns = utils.parseFilterPatterns(kwFilterExclude)
    local kwFilterActive = #includePatterns > 0 or #excludePatterns > 0
    local kwFilterData = {
        includePatterns = includePatterns,
        excludePatterns = excludePatterns,
        active = kwFilterActive,
    }

    local resetConnectioncount = 0
    local renditionParams = {
        stopIfCanceled = true,
    }
    -- flag to allow sync comments to manage process in PublishTaskImageProcessing.getCommentsFromPublishedCollection
    PWStatusManager.setRenderPhotos(publishService, true)

    -- now wait for photos to be exported and then upload to Piwigo
    for i, rendition in exportContext:renditions(renditionParams) do
        -- reset connection every 75 uploads
        resetConnectioncount = resetConnectioncount + 1
        if resetConnectioncount > 75 then
            resetConnectioncount = 0
            log:info("PublishTaskImageProcessing.processRenderedPhotos - resetting Piwigo connection after 75 uploads")
            rv = PiwigoAPI.login(propertyTable)
            if not rv then
                PWStatusManager.setPiwigoBusy(publishService, false)
                PWStatusManager.setRenderPhotos(publishService, false)
                log:info("PublishTaskImageProcessing.processRenderedPhotos - renditionSettings\n" ..
                    utils.serialiseVar(renditionParams))
                LrErrors.throwUserError('Publish photos to Piwigo - cannot connect to piwigo at ' ..
                    propertyTable.host)
                break
            end
        end

        local lrPhoto = rendition.photo
        local remoteId = rendition.publishedPhotoId or ""

        local existingPwImageId = nil
        local forceUpload = false
        if propertyTable.PWP_albumAssociation then
            log:info("PublishTaskImageProcessing.processRenderedPhotos - album association enabled")
            -- Detect photo already published in this service (multi-album support) if enabled via propertyTable.PWP_albumAssociation
            if remoteId == "" and propertyTable.PWP_albumAssociation then
                -- image does not have remoteID so is not in current Piwigo Album
                -- if album association is enabled then look for same image in another album of the same service,
                -- if found then associate to current album instead of uploading again, if not found then upload as new image

                local foundPubPhoto = nil
                local pubPhotoExists = false
                local foundPubCollection = nil

                if not existingPwImageId then
                    log:info("DEBUG multi-album: metadata empty, search cross-collection...")

                    pubPhotoExists, foundPubPhoto, foundPubCollection = utils.findExistingPwImageId(publishService,
                        lrPhoto,
                        publishedCollection)
                    if pubPhotoExists then
                        existingPwImageId = foundPubPhoto and foundPubPhoto:getRemoteId()
                    end

                    if existingPwImageId then
                        log:info("DEBUG multi-album: found via cross-collection, ID = " .. tostring(existingPwImageId))
                    end
                end

                -- Verify the image still exists on Piwigo

                if existingPwImageId then
                    local checkStatus = PiwigoAPI.checkPhoto(propertyTable, existingPwImageId)
                    if not checkStatus.status then
                        log:info("DEBUG multi-album: image " .. existingPwImageId .. " does not exist on Piwigo")
                        existingPwImageId = nil
                    else
                        -- the image exists in another album in the service
                        -- is the publishedPhoto:getEditedFlag() set - if so then force it to be reuploaded
                        if foundPubPhoto and foundPubPhoto:getEditedFlag() then
                            log:info("DEBUG multi-album: image " ..
                                existingPwImageId ..
                                " has been edited since last upload so force reupload to replace existing image on Piwigo")
                            forceUpload = true
                        end
                    end
                end
            end
        end

        -- ***************************************************
        -- Wait for next photo to render.
        -- ***************************************************
        local success, pathOrMessage = rendition:waitForRender()
        -- Check for cancellation again after photo has been rendered.
        if progressScope:isCanceled() then
            if LrFileUtils.exists(pathOrMessage) then
                LrFileUtils.delete(pathOrMessage)
            end
            break
        end

        if success then
            -- upload to Piwigo
            callStatus = {}
            local filePath = pathOrMessage

            -- If photo already exists on Piwigo, associate instead of uploading - will only be set if propertyTable.PWP_albumAssociation is true
            if existingPwImageId then
                log:info("Photo exists on Piwigo (ID " .. existingPwImageId .. "), associating to album " .. albumId)
                callStatus = PiwigoAPI.associateImageToCategory(propertyTable, existingPwImageId, albumId)
                if callStatus.status then
                    if not forceUpload then
                        log:info("Association successful, skipping upload")
                        -- record existing remote id and url for this photo and mark as done without uploading
                        rendition:recordPublishedPhotoId(callStatus.remoteid)
                        rendition:recordPublishedPhotoUrl(callStatus.remoteurl)
                        rendition:renditionIsDone(true)
                        LrFileUtils.delete(filePath)
                    else
                        -- association successful but we need to upload new version of photo, so we will upload and then update metadata for existing image on Piwigo with new md5 sum and other metadata, this way we keep the same remote id and url for the photo even when it is updated, which is important for multi-album support as it allows us to associate the same image to multiple albums without creating duplicates on Piwigo, and also means that if the photo is already published in another album then we won't end up with multiple versions of the same photo on Piwigo if we update it in Lightroom and republish.
                        log:info(
                            "Association successful but upload forced due to edited flag, will upload new version of photo and update metadata for existing image on Piwigo to keep same remote id and url")
                        remoteId = existingPwImageId
                    end
                else
                    log:warn("Association failed: " .. (callStatus.statusMsg or "") .. ", falling back to upload")
                    existingPwImageId = nil
                end
            end

            -- look for custom per-album export settings and re-render only when needed
            local customRenderInfo = getCustomRenderDecision(propertyTable, collectionSettings)
            if customRenderInfo.customEnabled then
                filePath = runCustomRenderForCollection(customRenderInfo, collectionSettings, rendition, filePath)
            end

            if not existingPwImageId or forceUpload then
                local metaData = {}
                -- build metadata structure
                -- need to add custom collection settings for title and caption

                metaData = utils.getPhotoMetadata(propertyTable, lrPhoto, collectionSettings)
                metaData.Albumid = albumId
                metaData.Remoteid = remoteId
                -- run to build missingTags - tags that will be created on upload to Piwigo
                -- will use this to decide whether to run build tagtable cache
                -- means we don't have to rebuild after each uploaded photo
                local tagIdList, missingTags = utils.tagsToIds(propertyTable, metaData.tagString)

                -- do the upload
                callStatus = PiwigoAPI.updateGallery(propertyTable, filePath, metaData)
                -- check status and complete rendition
                if callStatus.status then
                    rendition:recordPublishedPhotoId(callStatus.remoteid or "")
                    rendition:recordPublishedPhotoUrl(callStatus.remoteurl or "")
                    rendition:renditionIsDone(true)
                    -- set metadata for photo
                    local pluginData = {
                        pwHostURL = propertyTable.host,
                        albumName = albumName,
                        albumUrl = albumUrl,
                        imageUrl = callStatus.remoteurl,
                        pwUploadDate = os.date("%Y-%m-%d"),
                        pwUploadTime = os.date("%H:%M:%S"),
                        pwCommentSync = ""
                    }
                    if propertyTable.syncCommentsPublish then
                        -- set to allow comments to sync for this photo if flag set
                        pluginData.pwCommentSync = "YES"
                    end

                    -- store / update custom metadata
                    PiwigoAPI.storeMetaData(catalog, lrPhoto, pluginData)

                    -- photo was uploaded with keywords included, but existing keywords aren't replaced by this process,
                    -- also keyword filtering isn't applied to keywords embedded in the file at upload, so we need to apply filters separatelly
                    -- force a metadata update using pwg.images.setInfo with single_value_mode set to "replace" to force old metadata/keywords to be replaced
                    metaData.Remoteid = callStatus.remoteid
                    if missingTags then
                        -- refresh cached tag list as new tags have been created during updateGallery
                        rv, propertyTable.tagTable = PiwigoAPI.getTagList(propertyTable)
                        if not rv then
                            LrDialogs.message("PiwigoAPI:updateMetadata - cannot get taglist from Piwigo")
                        else
                            utils.buildTagIndex(propertyTable)
                        end
                    end

                    -- add kwfilterData to metaData so that it can be used in updateMetadata to apply keyword filters when updating keywords for existing photos
                    metaData.kwFilterData = kwFilterData
                    metaData.KwFullHierarchy = collectionSettings.KwFullHierarchy or true
                    metaData.KwSynonyms = collectionSettings.KwSynonyms or true
                    callStatus = PiwigoAPI.updateMetadata(propertyTable, lrPhoto, metaData)
                    if not callStatus.status then
                        LrDialogs.message("Unable to set metadata for uploaded photo - " .. callStatus.statusMsg)
                    end
                else
                    local sourcePhotoName = lrPhoto:getFormattedMetadata("fileName")
                    local anonymiseRenditionParams = utils.anonymiseRenditionParams(renditionParams)
                    local expRenditionParams = utils.serialiseVar(anonymiseRenditionParams)
                    local expMetaData = utils.serialiseVar(metaData)
                    log:info("Upload failed for photo: " .. sourcePhotoName)
                    log:info("Upload failed - renditionParams\n" .. expRenditionParams)
                    log:info("Upload failed - metaData\n" .. expMetaData)
                    log:info("Upload failed - propertyTable\n" ..
                        utils.serialiseVar(utils.anonymisePropertyTable(propertyTable)))
                    log:info("Upload failed - callStatus\n" .. utils.serialiseVar(callStatus))
                    log:info("Upload failed - filePath\n" .. filePath)

                    rendition:uploadFailed(callStatus.message or "Upload failed")
                end

                -- When done with photo, delete temp file.
                LrFileUtils.delete(filePath)
            end -- end if not existingPwImageId
        else
            rendition:uploadFailed(pathOrMessage or "Render failed")
        end
    end
    progressScope:done()
    PWStatusManager.setPiwigoBusy(publishService, false)
end

-- ************************************************
function PublishTaskImageProcessing.processCloneSync(functionContext, exportContext)
    -- minimal render function for service cloning
    log:info("PublishTaskImageProcessing.processCloneSync")
    local exportSession = exportContext.exportSession
    local propertyTable = exportContext.propertyTable

    local publishedCollection = exportContext.publishedCollection
    local publishService = publishedCollection:getService()


    local collectionInfo = publishedCollection:getCollectionInfoSummary()
    local collectionSettings = collectionInfo.collectionSettings or {}
    local collServiceState = {}
    local serviceState = {}
    if collectionSettings then
        collServiceState = collectionSettings.serviceState or {}
    end

    local collId = publishedCollection.localIdentifier
    local remoteInfoTable = collServiceState.RemoteInfoTable[collId] or {}

    local renditionParams = {
        stopIfCanceled = true,
    }
    for _, rendition in exportContext:renditions(renditionParams) do
        --rendition:skipRender()
        local lrPhoto = rendition.photo
        local photoId = lrPhoto.localIdentifier
        log:info("PublishTaskImageProcessing.processCloneSync - photo " .. lrPhoto:getFormattedMetadata("fileName"))

        local success, pathOrMessage = rendition:waitForRender()
        if not success then
            rendition:renditionIsDone(false, pathOrMessage)
            return
        end
        if LrFileUtils.exists(pathOrMessage) then
            LrFileUtils.delete(pathOrMessage)
        end
        -- extract remoteid and url
        local remoteInfo = remoteInfoTable[photoId]
        local remoteId = ""
        local remoteUrl = ""
        if remoteInfo then
            remoteId = remoteInfo.remoteId or ""
            remoteUrl = remoteInfo.remoteUrl or ""
        end

        if remoteId == "" then
            rendition:uploadFailed("Render failed - No remote id found")
        else
            rendition:recordPublishedPhotoId(remoteId)
            rendition:recordPublishedPhotoUrl(remoteUrl or "")
            rendition:renditionIsDone(true)
        end
    end
end

-- ************************************************
function PublishTaskImageProcessing.deletePhotosFromPublishedCollection(publishSettings, arrayOfPhotoIds, deletedCallback,
                                                                        localCollectionId)
    local callStatus = {}
    local errStatus = ""


    -- build tables to allow access to catalog LrPhoto object
    local catalog = LrApplication.activeCatalog()
    local publishedCollection = catalog:getPublishedCollectionByLocalIdentifier(localCollectionId)
    local publishedPhotos = publishedCollection:getPublishedPhotos()
    local publishService = publishedCollection:getService()
    if not publishService then
        log:info('deletePhotosFromPublishedCollection - publishSettings:\n' ..
            utils.serialiseVar(utils.anonymisePropertyTable(publishSettings)))
        LrErrors.throwUserError('Publish photos to Piwigo - cannot connect find publishService')
        return nil
    end
    -- serviceState is a global table containing publishService specific statusData
    local serviceState = PWStatusManager.getServiceState(publishService)
    if serviceState.PiwigoBusy then
        return nil
    end
    PWStatusManager.setPiwigoBusy(publishService, true)

    -- build lookup table to access photos by remoteId
    local photosToUnpublish = {}
    local pubPhotoByRemoteID = {}
    for _, pubPhoto in pairs(publishedPhotos) do
        pubPhotoByRemoteID[pubPhoto:getRemoteId()] = pubPhoto
    end

    -- build table of photo objects for each item in arrayofphotoids
    local arrayPos = 1
    for i = 1, #arrayOfPhotoIds do
        local pwImageID = arrayOfPhotoIds[i] or nil
        if pwImageID then
            local pubPhoto = pubPhotoByRemoteID[pwImageID]
            local lrphoto = pubPhoto:getPhoto()
            photosToUnpublish[arrayPos] = {}
            photosToUnpublish[arrayPos][1] = lrphoto
            photosToUnpublish[arrayPos][2] = pwImageID
            photosToUnpublish[arrayPos][3] = pubPhoto
            arrayPos = arrayPos + 1
        end
    end

    -- piwigo album id
    local pwCatID = publishedCollection:getRemoteId()

    -- check connection to piwigo
    if not (publishSettings.Connected) then
        local rv = PiwigoAPI.login(publishSettings)
        if not rv then
            PWStatusManager.setPiwigoBusy(publishService, false)
            LrErrors.throwUserError('Delete Photos from Collection - cannot connect to piwigo at ' .. publishSettings
                .url)
            return nil
        end
    end

    -- set up async prococess for piwigo calls
    LrTasks.startAsyncTask(function()
        -- now go through each photo in photosToUnpublish and remove from Piwigo
        for i, thisPhotoToUnpublish in pairs(photosToUnpublish) do
            local thisLrPhoto = thisPhotoToUnpublish[1]
            local thispwImageID = thisPhotoToUnpublish[2]
            local thisPubPhoto = thisPhotoToUnpublish[3]

            -- Use dissociate instead of delete to preserve multi-album associations
            log:info("PublishTaskImageProcessing.deletePhotosFromPublishedCollection - dissociating photo " ..
                thispwImageID .. " from category " .. pwCatID)

            callStatus = PiwigoAPI.dissociateImageFromCategory(publishSettings, thispwImageID, pwCatID)
            if callStatus.status then
                -- this call will dissociate image from album and also delete image from Piwigo if it is not associated to any other albums,
                if callStatus.deletedImage then
                    -- image was deleted from Piwigo as it was only associated to this album, so we can clear metadata
                    -- but same LrC image may still be in other albums and published as a different image on Piwigo (no album association)
                    -- so look for that and set metadata accordingly

                    local pubPhotoExists, foundPubPhoto, foundPubCollection = utils.findExistingPwImageId(publishService,
                        thisLrPhoto,
                        publishedCollection)

                    if pubPhotoExists then
                        -- photo exists in another album in the same service, so update metadata with new image url and id for that photo
                        local remoteUrl = foundPubPhoto:getRemoteUrl() or ""
                        local urlParts = utils.stringtoTable(remoteUrl, "/")
                        local albumId = urlParts[#urlParts]
                        local albumName = foundPubCollection:getName() or ""
                        local imageId = urlParts[#urlParts - 2]
                        local hostUrl = remoteUrl:match("(.-)picture%.php")
                        local albumUrl = string.format("%s/index.php?/category/%s", hostUrl, albumId)
                        -- get albumName from propertyTable.allCats
                        catalog:withWriteAccessDo("Updating " .. thisLrPhoto:getFormattedMetadata("fileName"),
                            function()
                                thisLrPhoto:setPropertyForPlugin(_PLUGIN, "pwHostURL", hostUrl)
                                thisLrPhoto:setPropertyForPlugin(_PLUGIN, "pwAlbumName", albumName)
                                thisLrPhoto:setPropertyForPlugin(_PLUGIN, "pwAlbumURL", albumUrl)
                                thisLrPhoto:setPropertyForPlugin(_PLUGIN, "pwImageURL", remoteUrl)
                                --thisLrPhoto:setPropertyForPlugin(_PLUGIN, "pwUploadDate", "")
                                --thisLrPhoto:setPropertyForPlugin(_PLUGIN, "pwUploadTime", "")
                                thisLrPhoto:setPropertyForPlugin(_PLUGIN, "pwCommentSync", "")
                            end)
                    else
                        log:info("PublishTaskImageProcessing.deletePhotosFromPublishedCollection - photo " ..
                            thispwImageID .. " deleted from Piwigo, clearing metadata")
                        catalog:withWriteAccessDo("Updating " .. thisLrPhoto:getFormattedMetadata("fileName"),
                            function()
                                thisLrPhoto:setPropertyForPlugin(_PLUGIN, "pwHostURL", "")
                                thisLrPhoto:setPropertyForPlugin(_PLUGIN, "pwAlbumName", "")
                                thisLrPhoto:setPropertyForPlugin(_PLUGIN, "pwAlbumURL", "")
                                thisLrPhoto:setPropertyForPlugin(_PLUGIN, "pwImageURL", "")
                                thisLrPhoto:setPropertyForPlugin(_PLUGIN, "pwUploadDate", "")
                                thisLrPhoto:setPropertyForPlugin(_PLUGIN, "pwUploadTime", "")
                                thisLrPhoto:setPropertyForPlugin(_PLUGIN, "pwCommentSync", "")
                            end)
                    end
                else
                    log:info("PublishTaskImageProcessing.deletePhotosFromPublishedCollection - photo " ..
                        thispwImageID .. " still in other collections, keeping metadata")
                end
                thisPhotoToUnpublish[4] = true
            else
                PWStatusManager.setPiwigoBusy(publishService, false)
                LrErrors.throwUserError(
                    'Failed to delete photo ' .. thispwImageID .. ' from Piwigo - ' .. callStatus.statusMsg,
                    'Failed to delete photo')
            end
        end
    end, errStatus)

    -- now finish process via deletedCallback
    for i, thisPhotoToUnpublish in pairs(photosToUnpublish) do
        local thispwImageID = thisPhotoToUnpublish[2]
        deletedCallback(thispwImageID)
    end


    PWStatusManager.setPiwigoBusy(publishService, false)
end

-- ************************************************
function PublishTaskImageProcessing.addCommentToPublishedPhoto(publishSettings, remotePhotoId, commentText)
    log:info("PublishTaskImageProcessing.addCommentToPublishedPhoto")
    -- add comment to Piwigo Photo

    local metaData = {}
    metaData.remoteId = remotePhotoId
    metaData.comment = commentText

    local rv = PiwigoAPI.addComment(publishSettings, metaData)
    return rv
end

-- ************************************************
function PublishTaskImageProcessing.getCommentsFromPublishedCollection(publishSettings, arrayOfPhotoInfo, commentCallback)
    log:info("PublishTaskImageProcessing.getCommentsFromPublishedCollection")

    --[[
    This callback is invoked in the following situations:
    1 - For every photo in the Published Collection whenever any photo in that collection is published or re-published.
    2 - When the user clicks Refresh in the Library module ▸ Comments panel.
    3 - After the user adds a new comment to a photo in the Library module ▸ Comments panel.
]]

    local rv, publishService = PiwigoAPI.getPublishService(publishSettings)
    if not (publishService) or not (rv) then
        log:info('PublishTaskImageProcessing.getCommentsFromPublishedCollection - publishSettings:\n' ..
            utils.serialiseVar(utils.anonymisePropertyTable(publishSettings)))
        LrErrors.throwUserError(
            'PublishTaskImageProcessing.getCommentsFromPublishedCollection - cannot find publishService')
        return nil
    end
    -- serviceState is a global table containing publishService specific statusData
    local serviceState = PWStatusManager.getServiceState(publishService)
    local serviceId = publishService.localIdentifier
    -- check serviceState.PiwigoBusy flag
    if serviceState.PiwigoBusy then
        utils.pwBusyMessage("PublishTaskImageProcessing.getCommentsFromPublishedCollection", "Sync Comments")
        return
    end

    -- check if being called by processRenderedPhotos
    local syncPubOnly = false
    if serviceState.RenderPhotos then
        PWStatusManager.setRenderPhotos(publishService, false)
        -- should we sync comments as part of the processRenderedPhotos operation
        if not (publishSettings.syncCommentsPublish) then
            log:info(
                "PublishTaskImageProcessing.getCommentsFromPublishedCollection - syncComments not enabled for publish")
            return
        end
        -- should we sync comments only for photos published in preceding publish process
        if publishSettings.syncCommentsPubOnly then
            syncPubOnly = true
        end
    end

    local catalog = LrApplication.activeCatalog()
    -- loop through all photos to check for any with pwCommentSync set to "NO"
    for i, photoInfo in ipairs(arrayOfPhotoInfo) do
        --log:info("PublishTaskImageProcessing.getCommentsFromPublishedCollection - photoInfo:\n" .. utils.serialiseVar(photoInfo))
        local thisPubPhoto = photoInfo.publishedPhoto
        local thisLrPhoto = thisPubPhoto:getPhoto()
        -- assume to sync comments for all photos in arrayofphotoids
        local syncThisPhoto = true
        if syncPubOnly then
            -- syncPubOnly will be set to true if getCommentsFromPublishedCollection has been called following processRenderedPhotos
            -- and user has checked the option Only Include Published Photos
            -- "pwCommentSync" gets set to YES by the renderphotos process indicating this photo is part of the latest publish process
            local commentSync = thisLrPhoto:getPropertyForPlugin(_PLUGIN, "pwCommentSync")
            if commentSync == "YES" then
                -- reset metadata
                catalog:withWriteAccessDo("Updating " .. thisLrPhoto:getFormattedMetadata("fileName"),
                    function()
                        thisLrPhoto:setPropertyForPlugin(_PLUGIN, "pwCommentSync", "")
                    end)
            else
                -- this photo was not part of recent processRenderedPhotos so ignore
                syncThisPhoto = false
            end
        end

        if syncThisPhoto then
            -- get table of comments for this photo from Piwigo
            local metaData = {}
            metaData.remoteId = photoInfo.remoteId
            local pwComments = PiwigoAPI.getComments(publishSettings, metaData)
            -- convert pwComments to format required by commentCallback
            --log:info("PublishTaskImageProcessing.getCommentsFromPublishedCollection - commentList:\n" .. utils.serialiseVar(pwComments))
            local commentList = {}
            if pwComments and #pwComments > 0 then
                for _, comment in ipairs(pwComments) do
                    local dateCreated = comment.date
                    local timeStamp = utils.timeStamp(dateCreated)
                    log:info("dateCreated " .. dateCreated .. ", timeStamp " .. timeStamp)
                    table.insert(commentList, {
                        commentId = comment.id,
                        commentText = comment.content,
                        dateCreated = LrDate.timeFromPosixDate(tonumber(timeStamp)),
                        username = comment.author,
                        realname = comment.author,
                        url = comment.page_url,
                    })
                end
            end
            --log:info("PublishTaskImageProcessing.getCommentsFromPublishedCollection - commentList:\n" .. utils.serialiseVar(commentList))
            commentCallback { publishedPhoto = photoInfo, comments = commentList }
        end
    end
end
