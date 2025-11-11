-- Global Initialisation
---@diagnostic disable: undefined-global

-- Global imports
_G.LrHttp = import 'LrHttp'
_G.LrDate = import 'LrDate'
_G.LrPathUtils = import 'LrPathUtils'
_G.LrFileUtils = import 'LrFileUtils'
_G.LrTasks = import 'LrTasks'
_G.LrErrors = import 'LrErrors'
_G.LrDialogs = import 'LrDialogs'
_G.LrView = import 'LrView'
_G.LrBinding = import 'LrBinding'
_G.LrColor = import 'LrColor'
_G.LrFunctionContext = import 'LrFunctionContext'
_G.LrApplication = import 'LrApplication'
_G.LrPrefs = import 'LrPrefs'
_G.LrShell = import 'LrShell'
_G.LrSystemInfo = import 'LrSystemInfo'
_G.LrProgressScope = import 'LrProgressScope'
_G.LrHttp = import 'LrHttp'
_G.LrMD5 = import 'LrMD5'
_G.LrExportSession = import 'LrExportSession'
_G.LrExportSettings = import "LrExportSettings"

-- Global requires
_G.JSON = require "JSON"
_G.utils = require "utils"
_G.defs = require "PWDefinitions"
_G.PWUtils = require "PiwigoAPI"
_G.PWSession = require "PWSession"
_G.PiwigoAPI = require "PiwigoAPI"


-- Global initializations
_G.prefs = _G.LrPrefs.prefsForPlugin()
_G.log = import 'LrLogger' ('piwigoPublish')
_G.log:enable('print')

