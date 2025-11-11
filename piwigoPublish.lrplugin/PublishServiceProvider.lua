-- PublishServiceProvider.lua
-- Publish Service Provider for Piwigo Publisher plugin

require "PublishDialogSections"
require "PublishTask"



return {
	
	startDialog = PublishDialogSections.startDialog,
	
	sectionsForTopOfDialog = PublishDialogSections.sectionsForTopOfDialog,
	
	sectionsForBottomOfDialog = PublishDialogSections.sectionsForBottomOfDialog,

	viewForCollectionSettings = PublishDialogSections.viewForCollectionSettings,
	
	endDialog = PublishDialogSections.endDialog,

	hideSections = { 'exportLocation' },


	allowFileFormats = nil,
	allowColorSpaces = nil,
	canExportVideo = false,
	supportsCustomSortOrder = false,
	hidePrintResolution = true,
	supportsIncrementalPublish = 'only', -- plugin only visible in publish services, not export
	canAddCommentsToService = false,
-- these fields are stored in the publish service settings by Lightroom
	exportPresetFields = {
		{ key = 'host', default = '' },
		{ key = "userName", default = '' },
		{ key = "userPW", default = '' },
		{ key = "tagRoot", default = "~Metadata|Publishing|Piwigo" },
	},
	-- metadataThatTriggersRepublish = {},

	-- canExportToTemporaryLocation = true -- not used 
	-- canExportToTemporaryLocation = true -- not used
	-- showSections = { 'fileNaming', 'fileSettings', etc... } -- not used
	small_icon = 'icons/logo_small.png',
	titleForPublishedCollection = 'Piwigo album',
	titleForPublishedSmartCollection = 'Piwigo album (Smart collection)',
	titleForGoToPublishedCollection = "Go to Album in Piwigo",

	

	getCollectionBehaviorInfo = PublishTask.getCollectionBehaviorInfo,

	processRenderedPhotos = PublishTask.processRenderedPhotos,

	addCommentToPublishedPhoto = PublishTask.addCommentToPublishedPhoto,

	getCommentsFromPublishedCollection = PublishTask.getCommentsFromPublishedCollection,

	deletePhotosFromPublishedCollection = PublishTask.deletePhotosFromPublishedCollection,

	deletePublishedCollection = PublishTask.deletePublishedCollection,

	renamePublishedCollection = PublishTask.renamePublishedCollection,
	
	reparentPublishedCollection =  PublishTask.reparentPublishedCollection,

	shouldDeletePhotosFromServiceOnDeleteFromCatalog = PublishTask.shouldDeletePhotosFromServiceOnDeleteFromCatalog,

	shouldDeletePublishService = PublishTask.shouldDeletePublishService,

	willDeletePublishService = PublishTask.willDeletePublishService,

	validatePublishedCollectionName = PublishTask.validatePublishedCollectionName,
	


}
