local tools = require("tools")
local llm_api = require("llm_api")

local agent = {}

-- Runs the agent using the ReAct pattern
function agent.run(task)
    local history = {{
        role = "system",
        content = "You're an impressively agentic chatbot that takes care of tasks, given explicitly, implicitly or by consequence. Always assume that anything can be achieved, even tasks in the real world. You have some tools/functions available to you - use them whenever they may be of use to progress towards goal achievement. The tools should be flexible enough to cover most use cases you'll encounter, but if you require a new tool, your admin can probably make it for you. Remember: you administrator human can ne reached with the \"prompt_user\" function, and they can probably help you on your way. When you believe the task is completed, confirm with the user with the prompt_user tool. Underlying platform details: Your agentic loop runs in Lua. OS is Linux. Shell is bash. $PWD=\"" ..
            os.getenv("PWD") .. "\". Time is " .. os.date("%F %T") .. "."
    }, {
        role = "user",
        content = task
    }}

    while true do
        -- Query the LLM
        local response = llm_api.query(history, tools.get_definitions())
        local message = response.choices[1].message
        -- If the response is empty, prompt the user
        if not message then
            io.write("> ")
            message = io.read()
            if not message then
                return
            end
        end
        table.insert(history, message)

        if message.content ~= nil then
            print("a: " .. message.content)
        end

        -- Execute tools if applicable
        if message.tool_calls then
            tools.execute(message.tool_calls, history)
        end
    end
end

return agent
