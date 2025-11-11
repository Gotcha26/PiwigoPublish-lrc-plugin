-- CustomMetadata.lua
-- Custom Metadata definitions for Piwigo Publisher plugin
return {
    metadataFieldsForPhotos = {
        {
            id = 'pwigoPhotoID',
            title = 'Piwigo Photo ID',
            dataType = 'string',
            readOnly = true,
        },
        {
            id = 'pwigoGalleryID',
            title = 'Piwigo Gallery ID',
            dataType = 'string',
            readOnly = true,
        },
        {
            id = 'pwigoUploadStatus',
            title = 'Piwigo Upload Status',
            dataType = 'string',
            readOnly = true,
        },
    },
}