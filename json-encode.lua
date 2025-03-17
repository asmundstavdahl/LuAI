--[[
  Simple JSON Encoder for Lua
  Supports: strings, numbers, booleans, tables, nil
  Does not support: custom serialization, formatting options
]]

-- Function to encode a Lua value to JSON
function encode(value)
  local valType = type(value)
  
  -- Handle nil
  if value == nil then
    return "null"
  end
  
  -- Handle strings
  if valType == "string" then
    return '"' .. string.gsub(value, '["\\\n\r\t]', function(c)
      if c == '"' then return '\\"' 
      elseif c == '\\' then return '\\\\'
      elseif c == '\n' then return '\\n'
      elseif c == '\r' then return '\\r'
      elseif c == '\t' then return '\\t'
      end
    end) .. '"'
  end
  
  -- Handle numbers
  if valType == "number" then
    return tostring(value)
  end
  
  -- Handle booleans
  if valType == "boolean" then
    return value and "true" or "false"
  end
  
  -- Handle tables (arrays and objects)
  if valType == "table" then
    -- Check if it's an array (consecutive integer keys starting from 1)
    local isArray = true
    local maxIndex = 0
    
    for k, v in pairs(value) do
      if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
        isArray = false
        break
      end
      maxIndex = math.max(maxIndex, k)
    end
    
    -- Check if all indices are present
    if isArray and maxIndex > 0 then
      for i = 1, maxIndex do
        if value[i] == nil then
          isArray = false
          break
        end
      end
    end
    
    -- Handle array
    if isArray then
      local items = {}
      for i = 1, maxIndex do
        items[i] = encode(value[i])
      end
      return "[" .. table.concat(items, ",") .. "]"
    end
    
    -- Handle object
    local items = {}
    for k, v in pairs(value) do
      if type(k) == "string" then
        table.insert(items, encode(k) .. ":" .. encode(v))
      end
    end
    return "{" .. table.concat(items, ",") .. "}"
  end
  
  error("Cannot encode value of type " .. valType)
end

return encode