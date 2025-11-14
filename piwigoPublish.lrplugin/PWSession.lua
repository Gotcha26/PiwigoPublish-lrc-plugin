--[[
    
    PiwigoSession.lua
    
    stores pwSession instances keyed by serviceID

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

PWSession = {}
local pwInstanceTable = {}  -- private table


-- ************************************************
-- store an instance keyed by serviceID
function PWSession.store(serviceID, instance)
    pwInstanceTable[serviceID] = instance
    log.debug('PWSession stored instance with serviceID: ' .. serviceID)
    log.debug('Contents are ' .. utils.serialiseVar(pwInstanceTable))
end

-- ************************************************
-- retrieve an instance by serviceID
function PWSession.get(serviceID)
    return pwInstanceTable[serviceID]
end

-- ************************************************
-- remove an instance when a service is deleted
function PWSession.remove(serviceID)
    pwInstanceTable[serviceID] = nil
end

return PWSession
