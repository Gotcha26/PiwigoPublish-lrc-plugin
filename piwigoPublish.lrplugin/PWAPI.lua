--[[

    Piwigo API

    see https://github.com/Piwigo/Piwigo/wiki/Piwigo-Web-API
    supports piwigo v16 with apiKey - https://piwigo.org/forum/viewtopic.php?id=34465

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


PWAPI = {}
PWAPI.__index = PWAPI

-- *************************************************
function PWAPI:new(url, apiKey)
    local o = setmetatable({}, PWAPI)
    self.deviceIdString = 'Lightroom Piwigo Publish Plugin'
    self.apiBasePath = "/ws.php?format=json"

    self.apiKey = apiKey
    self.url = url
    return o
end

-- *************************************************
function PWAPI:reconfigure(url, apiKey)

    self.apiKey = apiKey
    self.url = url
end
-- *************************************************

-- *************************************************

-- *************************************************

-- *************************************************

-- *************************************************

-- *************************************************

-- *************************************************


-- *************************************************
return PWAPI