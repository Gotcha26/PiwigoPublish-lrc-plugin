-- Tagset.lua
-- Tagset definitions for Piwigo Publisher plugin

return {
title = LOC "$$$/SampleTagset/Title=FJB Piwigo Publish Metadata", id = 'SSTagset',
items = { 
        'com.adobe.filename',
        'com.adobe.copyname',
        "com.adobe.dateTimeOriginal",
        'com.adobe.folder',

        'com.adobe.separator',
        'com.adobe.creator',
        'com.adobe.copyrightState',
        'com.adobe.copyright',
        'fiona.boston.UniversalPlugin.ccState',

        'com.adobe.separator',
	"com.adobe.imageFileDimensions",
	"com.adobe.imageCroppedDimensions",

        'com.adobe.separator',
        'com.adobe.title',
        {'com.adobe.caption', height_in_lines = 3 },
        'com.adobe.rating.string',
        {"com.adobe.altTextAccessibility", height_in_lines = 2 },

        {height_in_lines = 4, topLabel = true, allow_newlines = true,
                formatter = "com.adobe.extDescrAccessibility",
                label = "Extended Description"
	},

        "com.adobe.separator",
        {"com.adobe.GPS", label = "GPS"},
        "com.adobe.GPSAltitude",
        
        "com.adobe.separator",
        --{"com.adobe.keywords", height_in_lines = 3, topLabel = true,},
        {height_in_lines = 4, topLabel = true,
                formatter = "com.adobe.keywords",
                label = "Keywords"
	},

        'com.adobe.separator',
        'fiona.boston.UniversalPlugin.CLPublish',

        'com.adobe.separator',
        'fiona.boston.UniversalPlugin.Shoresearch',
        'fiona.boston.UniversalPlugin.ShoresearchShared',
        'fiona.boston.UniversalPlugin.IDConfidence',
        'fiona.boston.UniversalPlugin.AphiaID',
        'fiona.boston.UniversalPlugin.PiwigoID',
        'fiona.boston.UniversalPlugin.ObsID',

        'com.adobe.separator',
        'fiona.boston.UniversalPlugin.SquareRef',

        'com.adobe.separator',
        'fiona.boston.UniversalPlugin.OrtonEffect',
        'fiona.boston.UniversalPlugin.PhotoshopAI',
        {'fiona.boston.UniversalPlugin.PhotoshopNote', height_in_lines = 3},

        'com.adobe.separator',
        'fiona.boston.PwigoPublish.pwigoPhotoID',
        'fiona.boston.PwigoPublish.pwigoGalleryID',
        'fiona.boston.PwigoPublish.pwigoUploadStatus',  
        },
}