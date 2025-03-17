local config = require("config")
local util = require("util")

local llm_api = {}

function llm_api.query(messages, tools)
    local payload = util.to_json({
        model = config.model,
        messages = messages,
        tools = tools,
        tool_choice = "auto"
    })

    -- Encode payload to avoid shell injection issues
    local encoded_payload = util.to_base64(payload)

    -- Build the curl command using base64 decoding
    local cmd = string.format('echo "%s" | base64 -d | curl -s -w "%%{http_code}" -X POST "%s" ' ..
                                  '-H "Content-Type: application/json" -H "Authorization: Bearer %s" -d @-',
        encoded_payload, config.api_url, config.api_key)

    local handle = io.popen(cmd)
    local output = handle:read("*a")
    handle:close()

    -- Extract HTTP status code
    local http_code = tonumber(string.sub(output, -3))
    local body = string.sub(output, 1, -4)
    print(body)

    if http_code ~= 200 then
        error("Completion API request failed: HTTP " .. http_code .. " Response: " .. body)
    end

    -- print("Response:" .. body)

    return util.from_json(body)
end

return llm_api
