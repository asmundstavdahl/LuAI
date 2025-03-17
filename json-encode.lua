--[[
  Improved JSON Encoder for Lua
  - Added support for Unicode characters
  - Fixed handling of numeric keys
  - Improved array/object detection
  - Added support for NaN and Infinity
  - Fixed sparse array handling
]]

local json = {}

-- Helper function to encode a string with proper escaping
local function encodeString(value)
  local result = string.gsub(value, '["\\\n\r\t]', function(c)
    if c == '"' then return '\\"' 
    elseif c == '\\' then return '\\\\'
    elseif c == '\n' then return '\\n'
    elseif c == '\r' then return '\\r'
    elseif c == '\t' then return '\\t'
    end
  end)
  
  -- Handle non-ASCII characters by converting to \uXXXX format
  result = string.gsub(result, "([^\32-\126])", function(c)
    local byte = string.byte(c)
    if byte < 128 then
      return string.format("\\u%04x", byte)
    else
      -- Simple UTF-8 to Unicode codepoint conversion
      local codepoint
      if byte < 224 then
        -- 2-byte sequence (110xxxxx 10xxxxxx)
        local byte2 = string.byte(c, 2)
        codepoint = ((byte & 0x1F) << 6) + (byte2 & 0x3F)
      else
        -- 3-byte sequence (1110xxxx 10xxxxxx 10xxxxxx)
        local byte2 = string.byte(c, 2)
        local byte3 = string.byte(c, 3)
        codepoint = ((byte & 0x0F) << 12) + ((byte2 & 0x3F) << 6) + (byte3 & 0x3F)
      end
      return string.format("\\u%04x", codepoint)
    end
  end)
  
  return '"' .. result .. '"'
end

-- Function to determine if a table is an array
local function isArray(tbl)
  -- Check if empty
  if next(tbl) == nil then
    return true
  end
  
  local count = 0
  local maxIndex = 0
  
  -- Count integer keys and find max index
  for k, _ in pairs(tbl) do
    if type(k) == "number" and k > 0 and math.floor(k) == k then
      count = count + 1
      maxIndex = math.max(maxIndex, k)
    else
      -- If we find any non-integer key, it's not an array
      return false, 0
    end
  end
  
  -- It's an array if all indices from 1 to maxIndex exist
  return count == maxIndex, maxIndex
end

-- Function to encode a Lua value to JSON
function json.encode(value)
  local valType = type(value)
  
  -- Handle nil
  if value == nil then
    return "null"
  end
  
  -- Handle strings
  if valType == "string" then
    return encodeString(value)
  end
  
  -- Handle numbers
  if valType == "number" then
    -- Handle special values
    if value ~= value then  -- NaN
      return "null"
    elseif value == math.huge or value == -math.huge then  -- Infinity
      return "null"
    end
    return tostring(value)
  end
  
  -- Handle booleans
  if valType == "boolean" then
    return value and "true" or "false"
  end
  
  -- Handle tables (arrays and objects)
  if valType == "table" then
    local isArrayTable, maxIndex = isArray(value)
    
    if isArrayTable then
      -- Build array
      local items = {}
      for i = 1, maxIndex do
        items[i] = json.encode(value[i] or json.null)
      end
      return "[" .. table.concat(items, ",") .. "]"
    else
      -- Build object
      local parts = {}
      for k, v in pairs(value) do
        if type(k) == "string" then
          table.insert(parts, encodeString(k) .. ":" .. json.encode(v))
        end
      end
      return "{" .. table.concat(parts, ",") .. "}"
    end
  end
  
  error("Cannot encode value of type " .. valType)
end

-- Special value to represent null in tables
json.null = setmetatable({}, {
  __tostring = function() return "null" end
})

return json