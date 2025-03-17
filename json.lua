local json = {}

-- Helper: extract context around an error for debugging
local function errorContext(str, pos)
    local before = str:sub(math.max(1, pos - 10), pos - 1)
    local after = str:sub(pos, math.min(#str, pos + 10))
    return before .. ">>" .. after
end

-- Enhanced error reporting with context preview
local function errorAt(str, pos, msg)
    error(msg .. " at position " .. pos .. ": '" .. errorContext(str, pos) .. "'", 2)
end

-- Skip whitespace characters
local function skipWhitespace(str, pos)
    while pos <= #str do
        local c = str:sub(pos, pos)
        if c == " " or c == "\n" or c == "\r" or c == "\t" then
            pos = pos + 1
        else
            break
        end
    end
    return pos
end

-- Forward declarations for parser functions
local parseValue, parseObject, parseArray, parseString, parseNumber

function parseValue(str, pos)
    pos = skipWhitespace(str, pos)
    if pos > #str then
        errorAt(str, pos, "Unexpected end of input")
    end
    local c = str:sub(pos, pos)
    if c == "{" then
        return parseObject(str, pos)
    elseif c == "[" then
        return parseArray(str, pos)
    elseif c == "\"" then
        return parseString(str, pos)
    elseif c:match("[-0-9]") then
        return parseNumber(str, pos)
    elseif str:sub(pos, pos + 3) == "true" then
        return true, pos + 4
    elseif str:sub(pos, pos + 4) == "false" then
        return false, pos + 5
    elseif str:sub(pos, pos + 3) == "null" then
        return nil, pos + 4
    else
        errorAt(str, pos, "Invalid value")
    end
end

function parseObject(str, pos)
    local obj = {}
    pos = pos + 1 -- skip '{'
    pos = skipWhitespace(str, pos)
    if str:sub(pos, pos) == "}" then
        return obj, pos + 1
    end
    while true do
        pos = skipWhitespace(str, pos)
        if str:sub(pos, pos) ~= "\"" then
            errorAt(str, pos, "Expected '\"' for object key")
        end
        local key
        key, pos = parseString(str, pos)
        pos = skipWhitespace(str, pos)
        if str:sub(pos, pos) ~= ":" then
            errorAt(str, pos, "Expected ':' after key")
        end
        pos = pos + 1
        obj[key], pos = parseValue(str, pos)
        pos = skipWhitespace(str, pos)
        local c = str:sub(pos, pos)
        if c == "}" then
            return obj, pos + 1
        elseif c ~= "," then
            errorAt(str, pos, "Expected ',' or '}'")
        end
        pos = pos + 1
    end
end

function parseArray(str, pos)
    local arr = {}
    pos = pos + 1 -- skip '['
    pos = skipWhitespace(str, pos)
    if str:sub(pos, pos) == "]" then
        return arr, pos + 1
    end
    while true do
        local value
        value, pos = parseValue(str, pos)
        table.insert(arr, value)
        pos = skipWhitespace(str, pos)
        local c = str:sub(pos, pos)
        if c == "]" then
            return arr, pos + 1
        elseif c ~= "," then
            errorAt(str, pos, "Expected ',' or ']'")
        end
        pos = pos + 1
    end
end

function parseString(str, pos)
    pos = pos + 1 -- skip opening quote
    local result = {}
    local startPos = pos
    while pos <= #str do
        local c = str:sub(pos, pos)
        if c == "\"" then
            local chunk = str:sub(startPos, pos - 1)
            table.insert(result, chunk)
            return table.concat(result), pos + 1
        elseif c == "\\" then
            local chunk = str:sub(startPos, pos - 1)
            table.insert(result, chunk)
            pos = pos + 1
            if pos > #str then
                errorAt(str, pos, "Unfinished escape sequence")
            end
            local esc = str:sub(pos, pos)
            local escapeMap = {
                b = "\b",
                f = "\f",
                n = "\n",
                r = "\r",
                t = "\t"
            }
            table.insert(result, escapeMap[esc] or esc)
            pos = pos + 1
            startPos = pos
        else
            pos = pos + 1
        end
    end
    errorAt(str, pos, "Unterminated string")
end

function parseNumber(str, pos)
    local pattern = "^[-]?%d+%.?%d*[eE]?[+-]?%d*"
    local s, e = str:find(pattern, pos)
    if s ~= pos or s == nil then
        errorAt(str, pos, "Invalid number")
    end
    local numStr = str:sub(s, e)
    pos = e + 1
    local num = tonumber(numStr)
    if not num then
        errorAt(str, pos, "Invalid number format")
    end
    return num, pos
end

function json.decode(str)
    local pos = 1
    if str:sub(1, 3) == "\239\187\191" then
        pos = 4
    end -- Skip UTF-8 BOM if present
    local result
    result, pos = parseValue(str, pos)
    pos = skipWhitespace(str, pos)
    if pos <= #str then
        errorAt(str, pos, "Trailing characters after JSON data")
    end
    return result
end

-- Encoding functions

-- Recursive encoder that supports both pretty-printing and compact mode.
local function encodeValue(value, indent, level)
    local t = type(value)
    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return value and "true" or "false"
    elseif t == "number" then
        return tostring(value)
    elseif t == "string" then
        return '"' .. value:gsub('[%c\\"]', {
            ['"'] = '\\"',
            ['\\'] = '\\\\',
            ['\b'] = '\\b',
            ['\f'] = '\\f',
            ['\n'] = '\\n',
            ['\r'] = '\\r',
            ['\t'] = '\\t'
        }) .. '"'
    elseif t == "table" then
        local isArray = (#value > 0)
        local parts = {}

        if type(indent) == "number" then
            -- Pretty-print mode
            if isArray then
                local innerIndent = "\n" .. string.rep(" ", indent * level)
                local closingIndent = "\n" .. string.rep(" ", indent * (level - 1))
                for i, v in ipairs(value) do
                    table.insert(parts, encodeValue(v, indent, level + 1))
                end
                return "[" .. innerIndent .. table.concat(parts, "," .. innerIndent) .. closingIndent .. "]"
            else
                -- Sort object keys for deterministic output
                local keys = {}
                for k in pairs(value) do
                    table.insert(keys, k)
                end
                table.sort(keys) -- Ensures consistent order

                local innerIndent = "\n" .. string.rep(" ", indent * level)
                local closingIndent = "\n" .. string.rep(" ", indent * (level - 1))
                for _, k in ipairs(keys) do
                    table.insert(parts, '"' .. k .. '": ' .. encodeValue(value[k], indent, level + 1))
                end
                return "{" .. innerIndent .. table.concat(parts, "," .. innerIndent) .. closingIndent .. "}"
            end
        else
            -- Compact mode
            if isArray then
                for i, v in ipairs(value) do
                    table.insert(parts, encodeValue(v, false, level))
                end
                return "[" .. table.concat(parts, ",") .. "]"
            else
                -- Sort object keys for deterministic output
                local keys = {}
                for k in pairs(value) do
                    table.insert(keys, k)
                end
                table.sort(keys) -- Ensures consistent order

                for _, k in ipairs(keys) do
                    table.insert(parts, '"' .. k .. '":' .. encodeValue(value[k], false, level))
                end
                return "{" .. table.concat(parts, ",") .. "}"
            end
        end
    else
        error("Cannot encode unsupported type: " .. t)
    end
end

-- If the second argument is omitted, pretty printing is enabled (default 4 spaces).
-- To disable pretty printing, pass false as the second argument.
function json.encode(value, indent)
    if indent == nil then
        indent = 4
    end
    return encodeValue(value, indent, 1)
end

json.encode = require("json-encode").encode
json.decode = require("json-decode").decode

return json
