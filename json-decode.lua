--[[
  Simple JSON Decoder for Lua
  Supports: strings, numbers, booleans, arrays, objects, null
  Does not support: custom deserialization, advanced error handling
]]

local json = {}

-- Helper function to remove whitespace
local function removeWhitespace(str, index)
  while index <= #str and string.match(string.sub(str, index, index), "%s") do
    index = index + 1
  end
  return index
end

-- Parse a JSON string and return the value and the next position
function json.decode(str)
  local index = 1
  
  -- Forward declaration of parse function
  local parse
  
  -- Parse a string value
  local function parseString()
    local result = ""
    local escape = false
    
    index = index + 1 -- Skip opening quote
    
    while index <= #str do
      local char = string.sub(str, index, index)
      index = index + 1
      
      if escape then
        if char == '"' then result = result .. '"'
        elseif char == '\\' then result = result .. '\\'
        elseif char == '/' then result = result .. '/'
        elseif char == 'b' then result = result .. '\b'
        elseif char == 'f' then result = result .. '\f'
        elseif char == 'n' then result = result .. '\n'
        elseif char == 'r' then result = result .. '\r'
        elseif char == 't' then result = result .. '\t'
        elseif char == 'u' then
          -- Unicode escape sequence \uXXXX
          if index + 3 > #str then
            error("Incomplete Unicode escape sequence")
          end
          local hexValue = string.sub(str, index, index + 3)
          index = index + 4
          
          -- Convert hex to decimal
          local unicodeValue = tonumber(hexValue, 16)
          if not unicodeValue then
            error("Invalid Unicode escape sequence: \\u" .. hexValue)
          end
          
          -- Convert Unicode code point to UTF-8 encoded string
          -- Simple implementation for BMP characters (U+0000 to U+FFFF)
          if unicodeValue < 0x80 then
            -- Single byte (0xxxxxxx)
            result = result .. string.char(unicodeValue)
          elseif unicodeValue < 0x800 then
            -- Two bytes (110xxxxx 10xxxxxx)
            result = result .. string.char(
              0xC0 + math.floor(unicodeValue / 0x40),
              0x80 + (unicodeValue % 0x40)
            )
          else
            -- Three bytes (1110xxxx 10xxxxxx 10xxxxxx)
            result = result .. string.char(
              0xE0 + math.floor(unicodeValue / 0x1000),
              0x80 + math.floor((unicodeValue % 0x1000) / 0x40),
              0x80 + (unicodeValue % 0x40)
            )
          end
          
          -- Adjust index because we've already consumed 4 characters
          index = index - 1
        else
          -- Unsupported escape sequence
          error("Unsupported escape sequence: \\" .. char)
        end
        escape = false
      elseif char == '\\' then
        escape = true
      elseif char == '"' then
        break -- End of string
      else
        result = result .. char
      end
    end
    
    return result
  end
  
  -- Parse a number value
  local function parseNumber()
    local startIndex = index
    
    -- Handle negative numbers
    if string.sub(str, index, index) == '-' then
      index = index + 1
    end
    
    -- Parse integer part
    while index <= #str and string.match(string.sub(str, index, index), "%d") do
      index = index + 1
    end
    
    -- Parse decimal part
    if index <= #str and string.sub(str, index, index) == '.' then
      index = index + 1
      while index <= #str and string.match(string.sub(str, index, index), "%d") do
        index = index + 1
      end
    end
    
    -- Parse exponent part
    if index <= #str and string.match(string.sub(str, index, index), "[eE]") then
      index = index + 1
      if index <= #str and string.match(string.sub(str, index, index), "[+-]") then
        index = index + 1
      end
      while index <= #str and string.match(string.sub(str, index, index), "%d") do
        index = index + 1
      end
    end
    
    -- Convert to number
    return tonumber(string.sub(str, startIndex, index - 1))
  end
  
  -- Parse a JSON value
  parse = function()
    index = removeWhitespace(str, index)
    
    if index > #str then
      error("Unexpected end of input")
    end
    
    local char = string.sub(str, index, index)
    
    if char == '"' then
      return parseString()
    elseif char == '-' or string.match(char, "%d") then
      return parseNumber()
    elseif char == '{' then
      -- Parse object
      local result = {}
      index = index + 1
      
      index = removeWhitespace(str, index)
      if string.sub(str, index, index) == '}' then
        index = index + 1
        return result
      end
      
      while true do
        index = removeWhitespace(str, index)
        
        if string.sub(str, index, index) ~= '"' then
          error("Expected string key in object")
        end
        
        local key = parseString()
        
        index = removeWhitespace(str, index)
        if string.sub(str, index, index) ~= ':' then
          error("Expected ':' after key in object")
        end
        index = index + 1
        
        local value = parse()
        result[key] = value
        
        index = removeWhitespace(str, index)
        char = string.sub(str, index, index)
        index = index + 1
        
        if char == '}' then
          break
        elseif char ~= ',' then
          error("Expected ',' or '}' in object")
        end
      end
      
      return result
    elseif char == '[' then
      -- Parse array
      local result = {}
      index = index + 1
      
      index = removeWhitespace(str, index)
      if string.sub(str, index, index) == ']' then
        index = index + 1
        return result
      end
      
      local arrayIndex = 1
      
      while true do
        local value = parse()
        result[arrayIndex] = value
        arrayIndex = arrayIndex + 1
        
        index = removeWhitespace(str, index)
        char = string.sub(str, index, index)
        index = index + 1
        
        if char == ']' then
          break
        elseif char ~= ',' then
          error("Expected ',' or ']' in array")
        end
      end
      
      return result
    elseif index + 3 <= #str and string.sub(str, index, index + 3) == 'true' then
      index = index + 4
      return true
    elseif index + 4 <= #str and string.sub(str, index, index + 4) == 'false' then
      index = index + 5
      return false
    elseif index + 3 <= #str and string.sub(str, index, index + 3) == 'null' then
      index = index + 4
      return nil
    else
      error("Unexpected character: " .. char)
    end
  end
  
  -- Start parsing
  local result = parse()
  
  -- Check for trailing garbage
  index = removeWhitespace(str, index)
  if index <= #str then
    error("Trailing garbage after JSON value")
  end
  
  return result
end

return json