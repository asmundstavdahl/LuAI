local util = require("util")

local tools = {}
local registered_tools = {}

-- Register a new tool
function tools.register(name, description, parameters, implementation)
    registered_tools[name] = {
        name = name,
        description = description,
        parameters = parameters,
        implementation = implementation
    }
end

-- Get all tools in OpenAPI format
function tools.get_definitions()
    local definitions = {}
    for _, tool in pairs(registered_tools) do
        table.insert(definitions, {
            type = "function",
            ["function"] = {
                name = tool.name,
                description = tool.description,
                parameters = tool.parameters
            }
        })
    end
    return definitions
end

-- Execute a tool call
function tools.execute(tool_calls, history)
    for _, call in ipairs(tool_calls or {}) do
        -- print(util.to_json(call))
        local tool = registered_tools[call["function"].name]
        if tool then
            local args = util.from_json(call["function"].arguments)
            local result = tool.implementation(args)
            print(util.to_json(result))
            table.insert(history, {
                role = "tool",
                tool_call_id = call.id,
                name = call["function"].name,
                content = util.to_json(result)
            })
        else
            table.insert(history, {
                role = "system",
                content = "Tool not implemented: " .. call["function"].name
            })
        end
    end
end

-- Default "prompt_user" tool
tools.register("prompt_user", "Prompts the user for input when the agent requires guidance.", {
    type = "object",
    properties = {
        prompt = {
            type = "string",
            description = "The message to display to the user"
        }
    },
    required = {"prompt"}
}, function(params)
    io.write(params.prompt .. "\n> ")
    local response = io.read()
    return {
        response = response
    }
end)

return tools
