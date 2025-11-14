--[[

    utils.lua

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


local utils = {}

-- *************************************************
function utils.serialiseVar(value, indent)
    -- serialises an unknown variable
    indent = indent or ""
    local t = type(value)
    
    if t == "table" then
        local parts = {}
        table.insert(parts, "{\n")
        local nextIndent = indent .. "  "
        for k, v in pairs(value) do
            local key
            if type(k) == "string" then
                key = string.format("%q", k)
            else
                key = tostring(k)
            end
            table.insert(parts, nextIndent .. "[" .. key .. "] = " .. utils.serialiseVar(v, nextIndent) .. ",\n")
        end
        table.insert(parts, indent .. "}")
        return table.concat(parts)
    elseif t == "string" then
        return string.format("%q", value)
    else
        return tostring(value)
    end
end

-- *************************************************
function utils.uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

-- *************************************************
function utils.extractNumber(inStr)
-- Extract first number (integer or decimal, optional sign) from a string

    local num = string.match(inStr, "[-+]?%d+%.?%d*")
    if num then
        return tonumber(num)
    end
    return nil -- no number found
end

-- *************************************************
function utils.dmsToDecimal(deg, min, sec, hemi)
    -- convert DMS (degrees, minutes, seconds + direction) to decimal degrees
    local decimal = tonumber(deg) + tonumber(min) / 60
    if sec and sec ~= "" then
        decimal = decimal + tonumber(sec) / 3600
    end
    if hemi == "S" or hemi == "W" then
        decimal = -decimal
    end
    return decimal
end

-- *************************************************
function utils.parseSingleGPS(coordStr)
-- Try parsing a single coordinate (works for DMS or DM)
    local deg, min, sec, hemi = string.match(coordStr, "(%d+)°(%d+)'([%d%.]+)\"%s*([NSEW])")
    if deg then
        return utils.dmsToDecimal(deg, min, sec, hemi)
    end

    local deg2, min2, hemi2 = string.match(coordStr, "(%d+)°([%d%.]+)'%s*([NSEW])")
    if deg2 then
        return utils.dmsToDecimal(deg2, min2, nil, hemi2)
    end

    return nil -- not matched
end

-- *************************************************
function utils.parseGPS(coordStr)
    -- parse a coordinate string like: 51°13'31.9379" N 3°38'5.0159" W
    -- Split into two parts (latitude + longitude)
    local latStr, lonStr = string.match(coordStr, "^(.-)%s+([%d°'\"%sNSEW%.]+)$")
    if not latStr or not lonStr then
        return nil, nil, "Invalid coordinate format"
    end

    local lat = utils.parseSingleGPS(latStr)
    local lon = utils.parseSingleGPS(lonStr)

    return lat, lon

end

-- *************************************************
function utils.findNode(xmlNode,  nodeName )
    -- iteratively find nodeName in xmlNode

    if xmlNode:name() == nodeName then
        return xmlNode
    end

    for i = 1, xmlNode:childCount() do
        local child = xmlNode:childAtIndex(i)
        if child:type() == "element" then
            local found = utils.findNode(child, nodeName)
            if found then return found end
        end
    end
    return nil
end


-- *************************************************
function utils.fileExists(fName)

    local f = io.open(fName,"r")
    if f then 
        io.close(f)
        return true
    end
    return false
end

-- *************************************************
function utils.stringtoTable(inString, delim)
    -- create table based on passed in delimited string 
    local rtnTable = {}

    for substr in string.gmatch(inString, "[^".. delim.. "]*") do
        if substr ~= nil and string.len(substr) > 0 then
            table.insert(rtnTable,substr)
        end
    end

    return rtnTable
end

-- *************************************************
function utils.tabletoString(inTable, delim)
    local rtnString = ""
    for ss,value in pairs(inTable) do
        if rtnString == "" then
            rtnString = value
        else
            rtnString = rtnString .. delim .. value
        end
    end

    return rtnString
end


-- *************************************************
function utils.tagParse(tag)
  -- parse hierarchical tag structure (delimted by |) into table of individual elements
  local tag_table = {}
  for line in (tag .. "|"):gmatch("([^|]*)|") do
    table.insert(tag_table,line)
  end
  return tag_table
end

-- *************************************************
function utils.handleError(logMsg, userErrorMsg)
    -- function to log errors and throw user errors
    log:error(logMsg)
    LrDialogs.showError(userErrorMsg)
end

-- *************************************************
function utils.cutApiKey(key)
    -- replace characters of private string with elipsis
    return string.sub(key, 1, 20) .. '...'
end

---- *************************************************
function utils.GetKWHierarchy(kwHierarchy,thisKeyword,pos)
    -- build hierarchical list of parent keywords 
    kwHierarchy[pos] = thisKeyword
    if thisKeyword:getParent() == nil then
        return kwHierarchy
    end
    pos = pos + 1
    return(utils.GetKWHierarchy(kwHierarchy,thisKeyword:getParent(),pos))

end

---- *************************************************
function utils.GetKWfromHeirarchy(LrKeywords,kwStructure,logger)
    -- returns keyword from lowest element of hierarchical kwStructure (in form level1|level2|level3 ...)

    -- spilt kwStructure into individual elements
    local kwTable = utils.tagParse(kwStructure)
    local thisKW = nil
    local lastKWName = kwTable[#kwTable]
    if kwTable then
        for kk, kwName in ipairs(kwTable) do
            if thisKW then
                if thisKW:getName() == lastKWName then
                    return thisKW
                else
                    thisKW = utils.GetLrKeyword(thisKW:getChildren(),kwName)
                end
            else
                thisKW = utils.GetLrKeyword(LrKeywords,kwName)
            end

        end
    end
    return thisKW
end

-- *************************************************
function utils.GetLrKeyword(LrKeywords,keywordName)
    -- recursive function to return keyword with name matching keywordName
    for _, thisKeyword in ipairs(LrKeywords) do
        if thisKeyword:getName() == keywordName then
            return thisKeyword
        end
        -- Recursively search children
        local childMatch = utils.GetLrKeyword(thisKeyword:getChildren(), keywordName)
        if childMatch then
            return childMatch
        end
    end
    return nil
    
end


-- *************************************************
function utils.checkKw(thisPhoto, searchKw)
    -- does image contain keyword - returns keyword  or nil
    -- searchKw is string containing keyword to search for

    local kwHierarchy = {}
    local thisKwName = ""

    -- searchKw may be hierarchical - so split into each level
    local searchKwTable = utils.tagParse(searchKw)
    local searchKwLevels = #searchKwTable
    --log.debug("Looking for " .. searchKw .. " - " .. searchKwLevels .. " levels - " .. utils.serialiseVar(searchKwTable))

    local foundKW = nil -- return the keyword we find in this variable
    local stopSearch = false
    for ii, thisKeyword in ipairs(thisPhoto:getRawMetadata("keywords")) do

        -- thisKeyword is leaf node
        -- now need to build full hierarchical structure for thiskeyword
        kwHierarchy = {}
        kwHierarchy = utils.GetKWHierarchy(kwHierarchy,thisKeyword,1)
        local thisKwLevels = #kwHierarchy
        --log.debug("Checking image kw " .. thisKeyword:getName() .. " - " ..  thisKwLevels.. " levels ")
   
        for kk,kwLevel in ipairs(kwHierarchy) do
            local kwLevelName = kwLevel:getName()
            --log.debug("Level " .. kk .. " is " .. kwLevelName)
            if not stopSearch then
                if kwLevelName == searchKwTable[1] then
                    -- if we're looking for hierarchical kw need to check other levels for match aswell
                    if searchKwLevels > 1 then
                        --log.debug("Multi level kw search - " .. kwLevelName )
                        if thisKwLevels >= searchKwLevels then
                            local foundHKW = true
                            for hh = 2, searchKwLevels do
                                --log.debug("Multi level kw search at level - " .. hh .. ", " .. searchKwTable[hh] .. ", " .. kwHierarchy[kk-hh+1]:getName())
                                if searchKwTable[hh] ~= kwHierarchy[kk-hh+1]:getName() then
                                    foundHKW = false
                                end
                            end
                            if foundHKW then
                                foundKW = thisKeyword
                                --log.debug("Multilevel - Found " .. foundKW:getName())
                                stopSearch = true
                            end
                        end
                    else
                        foundKW = thisKeyword
                        --log.debug("Single Level - Found " .. foundKW:getName())
                        stopSearch = true
                    end
                end
            end
        end
    end
    return foundKW
end

-- *************************************************
local function normaliseId(id)
-- Normalise IDs for consistent comparison
    if id == nil then return nil end
    return tostring(id)
end

-- *************************************************
function utils.recursiveSearch(collNode, findName)
-- Recursively search for a published collection or published collection set
-- matching a given remoteId (string or number)

    --log.debug("recursiveSearch - collNode: " .. collNode:getName() .. " for name: " .. findName)
    --log.debug("recursiveSearch - collNode type is " .. tostring(collNode:type()))

    -- Check this collNode if it has a remote ID (only if collNode is a collection or set)
    if collNode:type() == 'LrPublishService' or collNode:type() == 'LrPublishedCollectionSet' then
        --log.debug("recursiveSearch 1 - " .. collNode:type(), collNode:getName())
        local thisName = collNode:getName()
        if thisName == findName then
            -- this collection or set matches
            --log.debug("recursiveSearch - ** MATCH ** collNode is matching node: " .. collNode:getName())
            return collNode
        end
    end
    -- Search immediate child collections
    if collNode.getChildCollections then
        local children = collNode:getChildCollections()
        if children then
            for _, coll in ipairs(children) do
                local type = coll:type()
                local thisName = coll:getName()
             --  log.debug("recursiveSearch 2 - " .. type,thisName)
                if thisName == findName then
                    -- this collection matches
                    --log.debug("recursiveSearch - ** MATCH ** Found matching collection: " .. coll:getName())
                    return coll
                end
            end
        end
    end

    -- Search child sets recursively
    if collNode.getChildCollectionSets then
        local collSets = collNode:getChildCollectionSets()
        if  collSets then
            for _, set in ipairs(collSets) do
                local foundSet = utils.recursiveSearch(set, findName)
                if foundSet then 
                    -- this set matches
                    --log.debug("recursiveSearch - ** MATCH ** Found matching collection set: " .. foundSet:getName())
                    return foundSet
                end
            end
        end
    end
    -- nothing found
    return nil
end

-- *************************************************
function utils.findPublishNodeByName(service, name)
    if not service or not name then 
        return nil 
    end
    return utils.recursiveSearch(service, normaliseId(name))
end

-- *************************************************
function utils.clean_spaces(text)
  --removes spaces from the front and back of passed in text
  text = string.gsub(text,"^%s*","")
  text = string.gsub(text,"%s*$","")
  return text
end

-- *************************************************
local function trim(s)
    -- Check if val is empty or nil
    -- Taken from https://github.com/midzelis/mi.Immich.Publisher/blob/main/utils.lua
    return s:match("^%s*(.-)%s*$")
end

-- *************************************************
function utils.nilOrEmpty(val)

    if val == nil then
        return true
    end
    if type(val) == "string" and val == "" then
        return true
    end
    if type(val) == "table" then
        -- Check if table has any elements (non-empty)
        for _ in pairs(val) do
            return false
        end
        return true
    end
    return false
end

-- *************************************************
-- http utiils
-- *************************************************
function utils.urlEncode(str)
    if str then
        str = string.gsub(str, "\n", "\r\n")
        str = string.gsub(str, "([^%w _%%%-%.~])",
            function(c) return string.format("%%%02X", string.byte(c)) end)
        str = string.gsub(str, " ", "+")
    end
    return str
end

-- *************************************************
function utils.buildGet(url,params)
  -- Helper to build GET URL with params
    local encoded = {}
    for k, param in pairs(params) do
        local name = utils.urlEncode(param.name) or ""
        local value = utils.urlEncode(param.value) or ""
        table.insert(encoded, name .. "=" ..value)
    end
    return url .. "&" .. table.concat(encoded, "&")
end

-- *************************************************
function utils.buildPost(params)
  -- Helper to build urlencoded POST params
    local post = {}
    for k, v in pairs(params) do
      table.insert(post, k .. "=" .. utils.urlEncode(v))
    end
    return table.concat(post, "&")

end

-- *************************************************
function utils.buildPostBodyFromParams(params)
  -- Helper to build urlencoded POST params
  -- take param table with name value pairs and return urlencoded string

    local parts = {}
    for _, pair in ipairs(params) do
        local name  = utils.urlEncode(pair.name or "")
        local value = utils.urlEncode(pair.value or "")
        table.insert(parts, string.format("%s=%s", name, value))
    end
    return table.concat(parts, "&")


end

-- *************************************************
function utils.buildHeader(params)
  -- Helper to build GET URL with params
   
    --[[
    local header = {}
    for k, param in pairs(params) do
        local name = param.name
able.concat(post, "&")        local value = param.value
        table.insert(header, name .. "=" ..value)
    end
    return table.concat(header, "&")
    ]]
    return params
end

-- *************************************************
function utils.mergeSplitCookies(headers)
    -- fix issue where LrHttp splits headers on commas, breaking some date values in cookies

    local merged = {}
    local lastWasCookie = false

    for _, h in ipairs(headers or {}) do
        if h.field:lower() == "set-cookie" then
            if lastWasCookie and h.value:match("^%s*%d%d%s") then
                -- This looks like a continuation of an Expires date (e.g. "Thu, 01 Jan 1970...")
                merged[#merged].value = merged[#merged].value .. ", " .. h.value
            else
                table.insert(merged, { field = h.field, value = h.value })
            end
            lastWasCookie = true
        else
            lastWasCookie = false
        end
    end

    return merged
end

-- *************************************************
function utils.extract_cookies(raw)
  -- Helper function to parse Set-Cookie headers into "key=value" pairs

  local cookies = {}
  -- Split by comma to separate multiple Set-Cookie headers
  for _, cookieStr in ipairs(raw) do
        -- A cookie string looks like: "SESSIONID=abc123; Path=/; HttpOnly"
        local firstPart = cookieStr:match("^[^;]+")   -- take only before first ";"
        if firstPart then
            local k, v = firstPart:match("^%s*([^=]+)=(.*)$")
            if k and v then
                cookies[k] = v
            end
        end
  end
  return cookies

end

-- *************************************************
function utils.build_url(base, params)
  -- Helper to build GET URL with params
    local query = {}
    for k, v in pairs(params) do
        table.insert(query, url.escape(k) .. "=" .. url.escape(v))
    end
    return base .. "?" .. table.concat(query, "&")
end

-- *************************************************
function utils.cURL_parse(result)
  local parse_table = {}
  local thisline = 1

  for line,newline in result:gmatch'([^\r\n]*)([\r\n]*)' do
    parse_table[thisline] = line
    thisline = thisline + 1
  end

  return parse_table

end

-- *************************************************
function utils.cURLcall(url)
  local restCMD = "curl --silent -i " .. url
  local result
  local payload = ""

  local cURLOutput = {} -- used to return status, errors and cURL results

  cURLOutput[1] = false
  local handle = io.popen(restCMD,"r")
  local linecount=1
  if handle then
    result = handle:read("*a")
    handle:close()
  else
    cURLOutput[2] = "Could not execute " .. restCMD
    return cURLOutput
  end

  local cURL_Parsed = utils.cURL_parse(result)
  -- http_code is second field (space delimited) of first element of cURL_Parsed
  local http_resp = utils.stringtoTable(cURL_Parsed[1]," ")
  local http_code = http_resp[2]
  if http_code ~= "200" then
    cURLOutput[2] = string.format("REST Service for %s returned http code %s", url, http_code )
    return cURLOutput
  end

  -- look for line with main payload
  for ii,value in ipairs(cURL_Parsed) do
    if (string.sub(value,1,3) == '[{"') or (string.sub(value,1,2) == '{"') then
      payload = value
      break
    end
  end
  cURLOutput[1] = true
  cURLOutput[2] = "OK"
  cURLOutput[3] = http_code
  cURLOutput[4] = payload
  return cURLOutput
end

-- *************************************************
function utils.httpGet(url)
  local payload = ""

  local cURLOutput = {} -- used to return status, errors and http results
  cURLOutput[1] = false
  local respParsed

  local httpResponse, httpHeaders = LrHttp.get(url)

    log.debug("httpget - calling " .. url)
    log.debug("headers are " .. utils.serialiseVar(httpHeaders))

  if httpResponse then
    respParsed = utils.cURL_parse(httpResponse)
    payload = respParsed[1]
    cURLOutput[1] = true
    cURLOutput[2] = httpHeaders.statusDes
    cURLOutput[3] = httpHeaders.status
    cURLOutput[4] = payload
  else
    if httpHeaders.error then
      cURLOutput[2] = httpHeaders.error.name
      cURLOutput[3] = httpHeaders.error.errorCode
    else
      cURLOutput[2] = httpHeaders.statusDes
      cURLOutput[3] = httpHeaders.status
    end
  end

  return cURLOutput
end

-- *************************************************
function utils.CallAPIGet(url)
  local cURLOutput = utils.httpGet(url)
  local status = cURLOutput[1]
  local statusMsg = cURLOutput[2]
  local http_code = cURLOutput[3]
  local payload = cURLOutput[4]
  local parsePayload

    log.debug("Url is " .. url)
    log.debug("cURLOutput is " .. utils.serialiseVar(cURLOutput))
    log.debug("payload is " .. type(payload) .. " - "  .. utils.serialiseVar(payload))

  if not status then
    local err = "Call to " .. url .. " failed - " .. http_code .. ", " .. statusMsg
    LrDialogs.message("APIGet Failed", err, "critical")
    return nil
  end

  if type(payload) == "string" and (payload == "[]" or payload == "{}") then
    parsePayload = ""
  else
    parsePayload = JSON:decode(payload)
  end

  --log.debug("parsepayload is " .. type(parsePayload) .. " - "  .. utils.serialiseVar(parsePayload))
  return parsePayload
end

-- *************************************************
function utils.httpPost(url, params)
  local cURLOutput = {} -- used to return status, errors and http results
  cURLOutput[1] = false
  local jsonBody = JSON:encode(params)
  
  local headers = {
    { field = 'Content-Type', value = 'application/json' }
  }

    log.debug("Http Post " .. url)
    log.debug("params " .. utils.serialiseVar(params))

  local result, httpHeaders = LrHttp.post(url, jsonBody, headers)

    log.debug("Result is " .. utils.serialiseVar(result))
    log.debug("Headers are " .. utils.serialiseVar(httpHeaders))



  if httpHeaders.status == 201 then
    cURLOutput[1] = true
    cURLOutput[2] = httpHeaders.statusDes
    cURLOutput[3] = httpHeaders.status
    cURLOutput[4] = result
  else
    if httpHeaders.error then
      cURLOutput[2] = httpHeaders.error.name
      cURLOutput[3] = httpHeaders.error.errorCode
    else
      cURLOutput[2] = httpHeaders.statusDes
      cURLOutput[3] = httpHeaders.status
    end
  end
  return cURLOutput

end

-- *************************************************
function utils.CallAPIPost(url, urlParams, table)
  local cURLOutput = utils.httpPost(url, urlParams)
  local status = cURLOutput[1]
  local statusMsg = cURLOutput[2]
  local http_code = cURLOutput[3]
  local payload = cURLOutput[4]
  local parsePayload
  if not status then
    local err = "Call to " .. url .. " failed - " .. http_code .. ", " .. statusMsg
    LrDialogs.message("API Post for " .. table .. " Failed", err, "critical")
    return nil
  end

    log.debug("Url is " .. url)
    log.debug("cURLOutput is " .. utils.serialiseVar(cURLOutput))
    log.debug("payload is " .. type(payload) .. " - "  .. utils.serialiseVar(payload))

  if type(payload) == "string" and (payload == "[]" or payload == "{}") then
    parsePayload = ""
  else
    parsePayload = JSON:decode(payload)
  end
  --log.debug("parsePayload is " .. utils.serialiseVar(parsePayload))
  return parsePayload
end

-- *************************************************
function utils.httpPostWithSink(url, body, headers, onDone, onError)
  log.debug("In httpPostWithSink function")
  local chunks, rawCookies = {}, {}

  local sink = {
      onHeaders = function(status, message, responseHeaders)
          for _, h in ipairs(responseHeaders or {}) do
              if h.field:lower() == "set-cookie" then
                  table.insert(rawCookies, h.value)
              end
          end
      end,

      onBody = function(chunk)
          if chunk and #chunk > 0 then
              table.insert(chunks, chunk)
          end
          return true
      end,

      onComplete = function()
          local response = table.concat(chunks)
          local parsedCookies = utils.extract_cookies(rawCookies)
          if onDone then
              onDone(response, parsedCookies, rawCookies)
          end
      end,

      onError = function(message)
          if onError then
              onError(message)
          end
      end,
  }

  return LrHttp.post(url, body, headers, sink)
end






-- *************************************************
return utils