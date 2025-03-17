local json = require("json")

local function assertEqual(actual, expected, msg)
    if actual ~= expected then
        error((msg or "Assertion failed") .. "\nExpected: " .. expected .. "\nGot: " .. actual, 2)
    end
end

local function test_json_encode()
    print("Running JSON encode tests...")

    -- Basic values
    assertEqual(json.encode(nil), "null", "Failed: nil")
    assertEqual(json.encode(true), "true", "Failed: boolean true")
    assertEqual(json.encode(false), "false", "Failed: boolean false")
    assertEqual(json.encode(42), "42", "Failed: integer")
    assertEqual(json.encode(3.14), "3.14", "Failed: float")
    assertEqual(json.encode("hello"), '"hello"', "Failed: string")
    assertEqual(json.encode("He said \"hello\""), '"He said \\"hello\\""', "Failed: string with quotes")

    -- Arrays (list-style tables)
    assertEqual(json.encode({1, 2, 3}), "[\n    1,\n    2,\n    3\n]", "Failed: basic array")
    assertEqual(json.encode({"a", "b", "c"}), '[\n    "a",\n    "b",\n    "c"\n]', "Failed: string array")

    -- Compact mode
    assertEqual(json.encode({1, 2, 3}, false), "[1,2,3]", "Failed: compact array")
    assertEqual(json.encode({
        a = 1,
        b = 2
    }, false), '{"a":1,"b":2}', "Failed: compact object")

    -- Objects (key-value tables)
    assertEqual(json.encode({
        key = "value"
    }), '{\n    "key": "value"\n}', "Failed: basic object")
    assertEqual(json.encode({
        a = 1,
        b = "text"
    }), '{\n    "a": 1,\n    "b": "text"\n}', "Failed: mixed object")

    -- Nested objects
    assertEqual(json.encode({
        a = {
            b = {
                c = "d"
            }
        }
    }), '{\n    "a": {\n        "b": {\n            "c": "d"\n        }\n    }\n}', "Failed: nested object")

    -- Empty tables
    assertEqual(json.encode({}), "{\n    \n}", "Failed: empty object")
    assertEqual(json.encode({}, false), "{}", "Failed: empty object (compact)")

    -- Special characters
    assertEqual(json.encode("\n\t"), '"\\n\\t"', "Failed: special characters")
    assertEqual(json.encode("backslash \\ test"), '"backslash \\\\ test"', "Failed: backslash escape")

    -- Large numbers
    assertEqual(json.encode(1234567890), "1234567890", "Failed: large number")

    -- Boolean keys (invalid case, should fail)
    local success, err = pcall(function()
        json.encode({
            [true] = "value"
        })
    end)
    assertEqual(success, false, "Failed: non-string key should error")

    print("✅ All JSON encode tests passed!")
end

test_json_encode()
