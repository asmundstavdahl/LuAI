local util = {}

-- Use json-lua for JSON operations.
local JSON = require("JSON")  -- Note the uppercase; json-lua is loaded as "JSON"

function util.to_json(value)
    return JSON:encode(value)
end

function util.from_json(str)
    return JSON:decode(str)
end

-- Try to load the 'mime' module from LuaSocket for Base64 encoding.
local has_mime, mime = pcall(require, "mime")

function util.to_base64(input)
    if has_mime and mime then
        return (mime.b64(input)):gsub("\n", "") -- Remove newlines for compatibility.
    else
        print("LuaSocket not found")
        -- Pure Lua Base64 encoding fallback.
        local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        return ((input:gsub('.', function(x)
            local r, b_val = '', x:byte()
            for i = 8, 1, -1 do
                r = r .. (b_val % 2^i - b_val % 2^(i-1) > 0 and '1' or '0')
            end
            return r
        end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
            if #x < 6 then return '' end
            local c = 0
            for i = 1, 6 do
                c = c + (x:sub(i, i) == '1' and 2^(6 - i) or 0)
            end
            return b:sub(c + 1, c + 1)
        end) .. ({ '', '==', '=' })[#input % 3 + 1])
    end
end

return util