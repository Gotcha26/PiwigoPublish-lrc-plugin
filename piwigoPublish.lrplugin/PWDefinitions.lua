-- *************************************************

local pwInstanceTable = {}

local PWDefs = {}

PWDefs.Piwigo = {
  pwhost            = "https://gallery.afboston.uk/",
  pwurl             = "https://gallery.afboston.uk/ws.php?format=json",
  pwuser            = "fiona",
  pwpassword        = "ZnnYV9lF4GTt7dw9OIdj",
  pwAPIKey          = "",
  Connected         = false,
  cookies           = {},
  login_response    = {},
  token             = "",
  userStatus        = "",
  stagingfolder     = "/Volumes/EXT-Photographs/Staging Folders/Piwigo",
  categories        = {},
  defaultCreator    = "Fiona Boston",
  defaultRights     = "Creative Commons Attribution-NonCommercial (CC BY-NC)"
}


PWDefs.Keywords = {
  PiwigoTag         = "~Metadata|Publishing|Piwigo",
  iRecTag           = "~Metadata|Publishing|iRecCSV",
  mastodonTag       = "~Metadata|Publishing|Mastodon"
}



PWDefs.ImgMetadata = {
  obsID           = "",
  piwigoID        = "",
  aphiaID         = "",
  date            = "",
  filename        = "",
  copyname        = "",
  gpsLat          = "",
  gpsLong         = "",
  elevation       = "",
  obvserver       = "",
  lrcuuid         = "",
  nathistKw       = {},
  lifestageKw     = {},
  siteCode        = {},
  surveyType      = {},
  surveyCode      = {},
  surveyZone      = {},
  photographer    = {},
  fullTaxonName   = "",
  taxonName       = "",
  lifeStage       = "",
  thisSite        = "",
  thisCode        = "",
  thisZone        = "",
  eventDate       = "",
  thisType        = "",
  catID           = "",
  title           = "",
  caption         = "",
  galleryurl      = ""


}

return PWDefs
