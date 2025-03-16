package.path = "/data/data/com.termux/files/home/.luarocks/share/lua/5.4/?.lua;" .. package.path
package.cpath = "/data/data/com.termux/files/home/.luarocks/lib/lua/5.4/?.so;" .. package.cpath

local agent = require("agent")
local tools = require("tools")

-- Register additional tools
tools.register(
    "calculate",
    "Evaluates a mathematical expression.",
    {
        type = "object",
        properties = {
            expression = { type = "string", description = "Math expression to evaluate (Lua syntax)" }
        },
        required = {"expression"}
    },
    function(params)
        print("calculate: " .. params.expression)
        local f, err = load("return " .. params.expression)
        if f then
            local ok, result = pcall(f)
            if ok then return { result = result } end
        end
        return { error = "Invalid expression" }
    end
)

-- Run the agent
io.write("Enter a task: ")
local task = io.read()
agent.run(task)