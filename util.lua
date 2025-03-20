local util = {}

local json = require("json")

function util.to_json(value)
    return json.encode(value)
end

function util.from_json(str)
    return json.decode(str)
end

function util.to_base64(input)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((input:gsub('.', function(x)
        local r, b_val = '', x:byte()
        for i = 8, 1, -1 do
            r = r .. (b_val % 2 ^ i - b_val % 2 ^ (i - 1) > 0 and '1' or '0')
        end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then
            return ''
        end
        local c = 0
        for i = 1, 6 do
            c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0)
        end
        return b:sub(c + 1, c + 1)
    end) .. ({'', '==', '='})[#input % 3 + 1])
end

return util
