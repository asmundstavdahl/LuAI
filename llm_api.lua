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

    -- print("\x1B[2m" .. payload .. "\x1B[0m")

    -- Encode payload to avoid shell injection issues
    local encoded_payload = util.to_base64(payload)

    -- print("\x1B[2m" .. encoded_payload .. "\x1B[0m")

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
    if http_code ~= 200 then
        error("Completion API request failed: HTTP " .. http_code .. " Response: " .. body)
    end

    -- print("\x1B[2m" .. body .. "\x1B[0m")

    local data = util.from_json(body)

    if data.error then
        error("Error " .. data.error.code .. " in response: " .. data.error.message)
    end

    return data
end

return llm_api
