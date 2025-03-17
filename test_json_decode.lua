local json = require("json")

local function assertEqual(actual, expected, msg)
    local t1, t2 = type(actual), type(expected)
    if t1 ~= t2 then
        error((msg or "Assertion failed") .. "\nMismatched types: Expected " .. t2 .. " but got " .. t1, 2)
    end
    if t1 == "table" then
        -- Recursive table comparison
        for k, v in pairs(expected) do
            assertEqual(actual[k], v, msg .. " (Mismatch at key: " .. tostring(k) .. ")")
        end
        for k in pairs(actual) do
            if expected[k] == nil then
                error(msg .. " (Unexpected key: " .. tostring(k) .. ")", 2)
            end
        end
    else
        if actual ~= expected then
            error((msg or "Assertion failed") .. "\nExpected: " .. tostring(expected) .. "\nGot: " .. tostring(actual),
                2)
        end
    end
end

local function test_json_decode()
    print("Running JSON decode tests...")

    -- Basic types
    assertEqual(json.decode("null"), nil, "Failed: null")
    assertEqual(json.decode("true"), true, "Failed: boolean true")
    assertEqual(json.decode("false"), false, "Failed: boolean false")
    assertEqual(json.decode("42"), 42, "Failed: integer")
    assertEqual(json.decode("3.14"), 3.14, "Failed: float")
    assertEqual(json.decode('"hello"'), "hello", "Failed: string")
    assertEqual(json.decode('"He said \\"hello\\""'), 'He said "hello"', "Failed: string with quotes")

    -- Arrays
    assertEqual(json.decode("[1, 2, 3]"), {1, 2, 3}, "Failed: basic array")
    assertEqual(json.decode('["a", "b", "c"]'), {"a", "b", "c"}, "Failed: string array")

    -- Objects
    assertEqual(json.decode('{"key": "value"}'), {
        key = "value"
    }, "Failed: basic object")
    assertEqual(json.decode('{"a": 1, "b": "text"}'), {
        a = 1,
        b = "text"
    }, "Failed: mixed object")

    -- Nested objects
    assertEqual(json.decode('{"a": {"b": {"c": "d"}}}'), {
        a = {
            b = {
                c = "d"
            }
        }
    }, "Failed: nested object")

    -- Empty structures
    assertEqual(json.decode("{}"), {}, "Failed: empty object")
    assertEqual(json.decode("[]"), {}, "Failed: empty array")

    -- Special characters
    assertEqual(json.decode('"\\n\\t"'), "\n\t", "Failed: special characters")
    assertEqual(json.decode('"backslash \\\\ test"'), "backslash \\ test", "Failed: backslash escape")

    -- Numbers
    assertEqual(json.decode("1234567890"), 1234567890, "Failed: large number")
    assertEqual(json.decode("-42"), -42, "Failed: negative integer")
    assertEqual(json.decode("0.0001"), 0.0001, "Failed: small float")

    -- Edge case: Extra whitespace
    assertEqual(json.decode("   { \"a\" : 1 }   "), {
        a = 1
    }, "Failed: extra whitespace handling")
    assertEqual(json.decode("\n\t[1, 2, 3]\t\n"), {1, 2, 3}, "Failed: extra whitespace in array")

    -- Error handling
    local function expectDecodeError(jsonStr, expectedError)
        local success, err = pcall(function()
            json.decode(jsonStr)
        end)
        assertEqual(success, false, "Expected decoding error: " .. expectedError)
    end

    expectDecodeError("{a:1}", "Invalid JSON (missing quotes around keys)")
    expectDecodeError("{'a':1}", "Invalid JSON (single quotes not allowed)")
    expectDecodeError("{\"a\":}", "Invalid JSON (missing value)")
    expectDecodeError("{\"a\": 1,}", "Invalid JSON (trailing comma)")
    expectDecodeError("[1, 2,]", "Invalid JSON (trailing comma in array)")
    expectDecodeError("{\"a\": 1 \"b\": 2}", "Invalid JSON (missing comma)")
    expectDecodeError("{\"a\": 1,", "Invalid JSON (unterminated object)")
    expectDecodeError("[1, 2", "Invalid JSON (unterminated array)")
    expectDecodeError("\"unterminated string", "Invalid JSON (unterminated string)")
    expectDecodeError("[1, true, null, , 5]", "Invalid JSON (missing value)")

    print("✅ All JSON decode tests passed!")
end

test_json_decode()
