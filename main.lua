package.path = "/data/data/com.termux/files/home/.luarocks/share/lua/5.4/?.lua;" .. package.path
package.cpath = "/data/data/com.termux/files/home/.luarocks/lib/lua/5.4/?.so;" .. package.cpath

local agent = require("agent")
local tools = require("tools")

-- Register additional tools
tools.register("evaluate_lua", "Evaluates a Lua expression.", {
    type = "object",
    properties = {
        expression = {
            type = "string",
            description = "Lua expression to evaluate."
        }
    },
    required = {"expression"}
}, function(params)
    print("evaluate_lua: " .. params.expression)
    local f, err = load("return " .. params.expression)
    if f then
        local ok, result = pcall(f)
        if ok then
            return {
                result = result
            }
        end
    end
    return {
        error = "Invalid expression (" .. err .. ")"
    }
end)

tools.register("execute_shell", "Executes a shell command using os.execute after user confirmation.", {
    type = "object",
    properties = {
        command = {
            type = "string",
            description = "Shell command to execute."
        }
    },
    required = {"command"}
}, function(params)
    print("execute_shell: " .. params.command)

    -- Ask for user confirmation
    io.write("Are you sure you want to execute this command? (yes/no): ")
    local response = io.read()

    if response:lower() == "yes" then
        local success, exit_reason, exit_code = os.execute(params.command)
        return {
            success = success,
            exit_reason = exit_reason,
            exit_code = exit_code
        }
    else
        return {
            error = "Execution cancelled by user."
        }
    end
end)

-- Run the agent
io.write("a: Yes?\n> ")
local task = io.read()
if type(task) == "string" then
    agent.run(task)
end
print("Bye")
