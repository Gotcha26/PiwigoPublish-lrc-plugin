local LrCUtils = {}

-- *************************************************
function LrCUtils.serialiseVar(value, indent)
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
            table.insert(parts, nextIndent .. "[" .. key .. "] = " .. LrCUtils.serialiseVar(v, nextIndent) .. ",\n")
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
function LrCUtils.uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

-- *************************************************
function LrCUtils.extractNumber(inStr)
-- Extract first number (integer or decimal, optional sign) from a string

    local num = string.match(inStr, "[-+]?%d+%.?%d*")
    if num then
        return tonumber(num)
    end
    return nil -- no number found


end

-- *************************************************
function LrCUtils.dmsToDecimal(deg, min, sec, hemi)
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
function LrCUtils.parseSingleGPS(coordStr)
-- Try parsing a single coordinate (works for DMS or DM)
    -- Try DMS first: 51°13'31.9379" N
    local deg, min, sec, hemi = string.match(coordStr, "(%d+)°(%d+)'([%d%.]+)\"%s*([NSEW])")
    if deg then
        return LrCUtils.dmsToDecimal(deg, min, sec, hemi)
    end

    -- Try DM: 51°13.5316' N
    local deg2, min2, hemi2 = string.match(coordStr, "(%d+)°([%d%.]+)'%s*([NSEW])")
    if deg2 then
        return LrCUtils.dmsToDecimal(deg2, min2, nil, hemi2)
    end

    return nil -- not matched
end

-- *************************************************
function LrCUtils.parseGPS(coordStr)
    -- parse a coordinate string like: 51°13'31.9379" N 3°38'5.0159" W
    -- Split into two parts (latitude + longitude)
    local latStr, lonStr = string.match(coordStr, "^(.-)%s+([%d°'\"%sNSEW%.]+)$")
    if not latStr or not lonStr then
        return nil, nil, "Invalid coordinate format"
    end

    local lat = LrCUtils.parseSingleGPS(latStr)
    local lon = LrCUtils.parseSingleGPS(lonStr)

    return lat, lon

end

-- *************************************************
function LrCUtils.findNode(xmlNode,  nodeName )
    -- iteratively find nodeName in xmlNode

    if xmlNode:name() == nodeName then
        return xmlNode
    end

    for i = 1, xmlNode:childCount() do
        local child = xmlNode:childAtIndex(i)
        if child:type() == "element" then
            local found = LrCUtils.findNode(child, nodeName)
            if found then return found end
        end
    end
    return nil
end


-- *************************************************
function LrCUtils.fileExists(fName)

    local f = io.open(fName,"r")
    if f then 
        io.close(f)
        return true
    end
    return false
end

-- *************************************************
function LrCUtils.stringtoTable(inString, delim)
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
function LrCUtils.tabletoString(inTable, delim)
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
function LrCUtils.tagParse(tag)
  -- parse hierarchical tag structure into table of individual elements
  local tag_table = {}
  for line in (tag .. "|"):gmatch("([^|]*)|") do
    table.insert(tag_table,line)
  end
  return tag_table
end

-- *************************************************
function LrCUtils.handleError(logMsg, userErrorMsg)
    -- function to log errors and throw user errors
    log:error(logMsg)
    LrDialogs.showError(userErrorMsg)
end

-- *************************************************
function LrCUtils.cutApiKey(key)
    return string.sub(key, 1, 20) .. '...'
end

---- *************************************************
function LrCUtils.GetKWHierarchy(kwHierarchy,thisKeyword,pos)
    -- build hierarchical list of parent keywords 
    kwHierarchy[pos] = thisKeyword
    if thisKeyword:getParent() == nil then
        return kwHierarchy
    end
    pos = pos + 1
    return(LrCUtils.GetKWHierarchy(kwHierarchy,thisKeyword:getParent(),pos))

end

---- *************************************************
function LrCUtils.GetKWfromHeirarchy(LrKeywords,kwStructure,logger)
    -- returns keyword from lowest element of hierarchical kwStructure (in form level1|level2|level3 ...)

    -- spilt kwStructure into individual elements
    local kwTable = LrCUtils.tagParse(kwStructure)
    local thisKW = nil
    local lastKWName = kwTable[#kwTable]
    if kwTable then
        for kk, kwName in ipairs(kwTable) do
            if thisKW then
                if thisKW:getName() == lastKWName then
                    return thisKW
                else
                    thisKW = LrCUtils.GetLrKeyword(thisKW:getChildren(),kwName)
                end
            else
                thisKW = LrCUtils.GetLrKeyword(LrKeywords,kwName)
            end

        end
    end
    return thisKW
end

-- *************************************************
function LrCUtils.GetLrKeyword(LrKeywords,keywordName)
    -- return keyword with name matching keywordName
    for _, thisKeyword in ipairs(LrKeywords) do
        if thisKeyword:getName() == keywordName then
            return thisKeyword
        end
        -- Recursively search children
        local childMatch = LrCUtils.GetLrKeyword(thisKeyword:getChildren(), keywordName)
        if childMatch then
            return childMatch
        end
    end
    return nil
    
end


-- *************************************************
function LrCUtils.checkKw(thisPhoto, searchKw)
    -- does image contain keyword - returns keyword  or nil
    -- searchKw is string containing keyword to search for
    -- need to iterate through keyword and all parent keywords 

    local kwHierarchy = {}
    local thisKwName = ""

    -- searchKw may be hierarchical - so split into each level
    local searchKwTable = LrCUtils.tagParse(searchKw)
    local searchKwLevels = #searchKwTable
    --log:info("Looking for " .. searchKw .. " - " .. searchKwLevels .. " levels - " .. LrCUtils.serialiseVar(searchKwTable))

    local foundKW = nil -- return the keyword we find in this variable
    local stopSearch = false
    for ii, thisKeyword in ipairs(thisPhoto:getRawMetadata("keywords")) do

        -- thisKeyword is leaf node
        -- now need to build full hierarchical structure for thiskeyword
        kwHierarchy = {}
        kwHierarchy = LrCUtils.GetKWHierarchy(kwHierarchy,thisKeyword,1)
        local thisKwLevels = #kwHierarchy
        --log:info("Checking image kw " .. thisKeyword:getName() .. " - " ..  thisKwLevels.. " levels ")
   
        for kk,kwLevel in ipairs(kwHierarchy) do
            local kwLevelName = kwLevel:getName()
            --log:info("Level " .. kk .. " is " .. kwLevelName)
            if not stopSearch then
                if kwLevelName == searchKwTable[1] then
                    -- if we're looking for hierarchical kw need to check other levels for match aswell
                    if searchKwLevels > 1 then
                        --log:info("Multi level kw search - " .. kwLevelName )
                        if thisKwLevels >= searchKwLevels then
                            local foundHKW = true
                            for hh = 2, searchKwLevels do
                                --log:info("Multi level kw search at level - " .. hh .. ", " .. searchKwTable[hh] .. ", " .. kwHierarchy[kk-hh+1]:getName())
                                if searchKwTable[hh] ~= kwHierarchy[kk-hh+1]:getName() then
                                    foundHKW = false
                                end
                            end
                            if foundHKW then
                                foundKW = thisKeyword
                                --log:info("Multilevel - Found " .. foundKW:getName())
                                stopSearch = true
                            end
                        end
                    else
                        foundKW = thisKeyword
                        --log:info("Single Level - Found " .. foundKW:getName())
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
function LrCUtils.recursiveSearch(collNode, findName)

-- Recursively search for a collection or collection set
-- matching a given remoteId (string or number)
    log:trace("recursiveSearch - collNode: " .. collNode:getName() .. " for name: " .. findName)
    log:trace("recursiveSearch - collNode type is " .. tostring(collNode:type()))

    -- Check this collNode if it has a remote ID (only if collNode is a collection or set)
    if collNode:type() == 'LrPublishService' or collNode:type() == 'LrPublishedCollectionSet' then
        log:trace("recursiveSearch 1 - " .. collNode:type(), collNode:getName())
        local thisName = collNode:getName()
        if thisName == findName then
            -- this collection or set matches
            log:trace("recursiveSearch - ** MATCH ** collNode is matching node: " .. collNode:getName())
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


                log:trace("recursiveSearch 2 - " .. type,thisName)

                if thisName == findName then
                    -- this collection matches
                    log:trace("recursiveSearch - ** MATCH ** Found matching collection: " .. coll:getName())
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
                local foundSet = LrCUtils.recursiveSearch(set, findName)
                if foundSet then 
                    -- this set matches
                    log:trace("recursiveSearch - ** MATCH ** Found matching collection set: " .. foundSet:getName())
                    return foundSet
                end
            end
        end
    end

    -- nothing found
    return nil
end

-- *************************************************
function LrCUtils.findPublishNodeByName(service, name)
    if not service or not name then 
        return nil 
    end
    return LrCUtils.recursiveSearch(service, normaliseId(name))
end

-- *************************************************
function LrCUtils.clean_spaces(text)
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
function LrCUtils.nilOrEmpty(val)
    -- Taken from https://github.com/midzelis/mi.Immich.Publisher/blob/main/utils.lua
    if type(val) == 'string' then
        return val == nil or trim(val) == ''
    else
        return val == nil
    end
end

-- *************************************************
-- http utiils
-- *************************************************
function LrCUtils.urlEncode(str)
    if str then
        str = string.gsub(str, "\n", "\r\n")
        str = string.gsub(str, "([^%w _%%%-%.~])",
            function(c) return string.format("%%%02X", string.byte(c)) end)
        str = string.gsub(str, " ", "+")
    end
    return str
end

-- *************************************************
function LrCUtils.buildGet(url,params)
  -- Helper to build GET URL with params
    local encoded = {}
    for k, param in pairs(params) do
        local name = LrCUtils.urlEncode(param.name)
        local value = LrCUtils.urlEncode(param.value)
        table.insert(encoded, name .. "=" ..value)
    end
    return url .. "&" .. table.concat(encoded, "&")
end

-- *************************************************
function LrCUtils.buildPost(params)
  -- Helper to build urlencoded POST params
    local post = {}
    for k, v in pairs(params) do
      table.insert(post, k .. "=" .. LrCUtils.urlEncode(v))
    end
    return table.concat(post, "&")

end

-- *************************************************
function LrCUtils.buildHeader(params)
  -- Helper to build GET URL with params
   
    --[[
    local header = {}
    for k, param in pairs(params) do
        local name = param.name
        local value = param.value
        table.insert(header, name .. "=" ..value)
    end
    return table.concat(header, "&")
    ]]
    return params
end

-- *************************************************
function LrCUtils.extract_cookies(raw)
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
function LrCUtils.build_url(base, params)
  -- Helper to build GET URL with params
    local query = {}
    for k, v in pairs(params) do
        table.insert(query, url.escape(k) .. "=" .. url.escape(v))
    end
    return base .. "?" .. table.concat(query, "&")
end

-- *************************************************
function LrCUtils.cURL_parse(result)
  local parse_table = {}
  local thisline = 1

  for line,newline in result:gmatch'([^\r\n]*)([\r\n]*)' do
    parse_table[thisline] = line
    thisline = thisline + 1
  end

  return parse_table

end

-- *************************************************
function LrCUtils.cURLcall(url)
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

  local cURL_Parsed = LrCUtils.cURL_parse(result)
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
function LrCUtils.httpGet(url,debug)
  local payload = ""

  local cURLOutput = {} -- used to return status, errors and http results
  cURLOutput[1] = false
  local respParsed

  local httpResponse, httpHeaders = LrHttp.get(url)
  if debug then
    log:info("httpget - calling " .. url)
    log:info("headers are " .. utils.serialiseVar(httpHeaders))
  end
  if httpResponse then
    respParsed = LrCUtils.cURL_parse(httpResponse)
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
function LrCUtils.CallAPIGet(url,debug)
  local cURLOutput = LrCUtils.httpGet(url, debug)
  local status = cURLOutput[1]
  local statusMsg = cURLOutput[2]
  local http_code = cURLOutput[3]
  local payload = cURLOutput[4]
  local parsePayload
  if debug then
    log:info("Url is " .. url)
    log:info("cURLOutput is " .. utils.serialiseVar(cURLOutput))
    log:info("payload is " .. type(payload) .. " - "  .. utils.serialiseVar(payload))
  end
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

  --log:info("parsepayload is " .. type(parsePayload) .. " - "  .. utils.serialiseVar(parsePayload))
  return parsePayload
end

-- *************************************************
function LrCUtils.httpPost(url, params, debug)
  local cURLOutput = {} -- used to return status, errors and http results
  cURLOutput[1] = false
  local jsonBody = JSON:encode(params)
  
  local headers = {
    { field = 'Content-Type', value = 'application/json' }
  }
  if debug then 
    log:info("Http Post " .. url)
    log:info("params " .. utils.serialiseVar(params))
  end
  local result, httpHeaders = LrHttp.post(url, jsonBody, headers)
  if debug then 
    log:info("Result is " .. utils.serialiseVar(result))
    log:info("Headers are " .. utils.serialiseVar(httpHeaders))
  end


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
function LrCUtils.CallAPIPost(url, urlParams, table, debug)
  local cURLOutput = LrCUtils.httpPost(url, urlParams, debug)
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
  if debug then
    log:info("Url is " .. url)
    log:info("cURLOutput is " .. utils.serialiseVar(cURLOutput))
    log:info("payload is " .. type(payload) .. " - "  .. utils.serialiseVar(payload))
  end
  if type(payload) == "string" and (payload == "[]" or payload == "{}") then
    parsePayload = ""
  else
    parsePayload = JSON:decode(payload)
  end
  --log:info("parsePayload is " .. utils.serialiseVar(parsePayload))
  return parsePayload
end

-- *************************************************
function LrCUtils.httpPostWithSink(url, body, headers, onDone, onError)
  log:info("In httpPostWithSink function")
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
          local parsedCookies = LrCUtils.extract_cookies(rawCookies)
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
return LrCUtils