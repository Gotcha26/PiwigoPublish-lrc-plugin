-- PiwigoSession.lua
-- stores pwSession instances keyed by serviceID
-- ensures multple service instances do not interfere


PWSession = {}
local pwInstanceTable = {}  -- private table


-- ************************************************
-- store an instance keyed by serviceID
function PWSession.store(serviceID, instance)
    pwInstanceTable[serviceID] = instance
    log:trace('PWSession stored instance with serviceID: ' .. serviceID)
    log:trace('Contents are ' .. utils.serialiseVar(pwInstanceTable))
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
