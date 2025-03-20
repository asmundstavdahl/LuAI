local util = {}

local json = require("json")
local base64 = require("base64")

function util.to_json(value)
    return json.encode(value)
end

function util.from_json(str)
    return json.decode(str)
end

function util.to_base64(input)
    return base64.encode(input)
end

return util
