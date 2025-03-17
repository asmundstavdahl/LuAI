--[[
  Unit Tests for Simple Lua JSON Encoder
  Tests a full spectrum of JSON encoding features and edge cases
]]

-- Load the JSON encoder module (adjust path as needed)
local json = require("json")

-- Simple test runner
local function runTests()
  local passCount, failCount = 0, 0
  local failures = {}
  
  local function assertEqual(expected, actual, testName)
    if expected == actual then
      passCount = passCount + 1
      print("PASS: " .. testName)
    else
      failCount = failCount + 1
      print("FAIL: " .. testName)
      print("  Expected: " .. tostring(expected))
      print("  Actual:   " .. tostring(actual))
      table.insert(failures, testName)
    end
  end
  
  -- Test 1: Encode null (nil)
  assertEqual("null", json.encode(nil), "Encoding nil should produce 'null'")
  
  -- Test 2-8: Encode basic types
  assertEqual("true", json.encode(true), "Encoding boolean true")
  assertEqual("false", json.encode(false), "Encoding boolean false")
  assertEqual("42", json.encode(42), "Encoding integer number")
  assertEqual("42.5", json.encode(42.5), "Encoding decimal number")
  assertEqual("-10", json.encode(-10), "Encoding negative integer")
  assertEqual("-3.14", json.encode(-3.14), "Encoding negative decimal")
  assertEqual("0", json.encode(0), "Encoding zero")
  
  -- Test 9-18: Encode strings with different characteristics
  assertEqual("\"hello\"", json.encode("hello"), "Encoding basic string")
  assertEqual("\"\"", json.encode(""), "Encoding empty string")
  assertEqual("\"hello world\"", json.encode("hello world"), "Encoding string with space")
  assertEqual("\"\\\"quoted\\\"\"", json.encode("\"quoted\""), "Encoding string with quotes")
  assertEqual("\"line1\\nline2\"", json.encode("line1\nline2"), "Encoding string with newline")
  assertEqual("\"tab\\tcharacter\"", json.encode("tab\tcharacter"), "Encoding string with tab")
  assertEqual("\"backslash\\\\character\"", json.encode("backslash\\character"), "Encoding string with backslash")
  assertEqual("\"control\\rcharacter\"", json.encode("control\rcharacter"), "Encoding string with carriage return")
  assertEqual("\"mixed\\\"\\\\\\n\\r\\tcharacters\"", json.encode("mixed\"\\\n\r\tcharacters"), "Encoding string with mixed special chars")
  assertEqual("\"unicode character: \\u00A9\"", json.encode("unicode character: ©"), "Encoding string with non-ASCII character")
  
  -- Test 19-25: Encode arrays of different types
  assertEqual("[]", json.encode({}), "Encoding empty array")
  assertEqual("[1,2,3]", json.encode({1, 2, 3}), "Encoding array of integers")
  assertEqual("[\"a\",\"b\",\"c\"]", json.encode({"a", "b", "c"}), "Encoding array of strings")
  assertEqual("[true,false,true]", json.encode({true, false, true}), "Encoding array of booleans")
  assertEqual("[1,\"two\",3]", json.encode({1, "two", 3}), "Encoding array of mixed types")
  assertEqual("[1,[2,3],4]", json.encode({1, {2, 3}, 4}), "Encoding nested arrays")
  assertEqual("[1,{\"a\":\"b\"},3]", json.encode({1, {a = "b"}, 3}), "Encoding array with object")
  
  -- Test 26-32: Encode objects of different types
  assertEqual("{}", json.encode({[1] = "a"}), "Encoding object with numeric key (should be empty object)")
  assertEqual("{\"a\":1}", json.encode({a = 1}), "Encoding simple object with number value")
  assertEqual("{\"a\":\"b\"}", json.encode({a = "b"}), "Encoding simple object with string value")
  assertEqual("{\"a\":true}", json.encode({a = true}), "Encoding simple object with boolean value")
  assertEqual("{\"a\":null}", json.encode({a = nil}), "Encoding object with nil value (should be empty object)")
  assertEqual("{\"a\":{\"b\":2}}", json.encode({a = {b = 2}}), "Encoding nested objects")
  assertEqual("{\"a\":[1,2,3]}", json.encode({a = {1, 2, 3}}), "Encoding object with array value")
  
  -- Test 33-38: Encode complex nested structures
  local complex1 = {
    name = "John",
    age = 30,
    isActive = true,
    hobbies = {"reading", "swimming"},
    address = {
      street = "123 Main St",
      city = "New York"
    }
  }
  assertEqual(
    "{\"address\":{\"city\":\"New York\",\"street\":\"123 Main St\"},\"age\":30,\"hobbies\":[\"reading\",\"swimming\"],\"isActive\":true,\"name\":\"John\"}",
    json.encode(complex1),
    "Encoding complex nested structure with arrays and objects"
  )
  
  local complex2 = {
    data = {
      users = {
        {id = 1, name = "Alice", active = true},
        {id = 2, name = "Bob", active = false}
      },
      metadata = {
        count = 2,
        page = 1
      }
    },
    success = true
  }
  assertEqual(
    "{\"data\":{\"metadata\":{\"count\":2,\"page\":1},\"users\":[{\"active\":true,\"id\":1,\"name\":\"Alice\"},{\"active\":false,\"id\":2,\"name\":\"Bob\"}]},\"success\":true}",
    json.encode(complex2),
    "Encoding deeply nested structure with arrays of objects"
  )
  
  -- Test 39-44: Edge cases
  assertEqual("[]", json.encode({[2] = "a"}), "Encoding array with missing index 1 (should be empty array)")
  local sparseArray = {}
  sparseArray[1] = "first"
  sparseArray[3] = "third"
  assertEqual("{\"1\":\"first\",\"3\":\"third\"}", json.encode(sparseArray), "Encoding sparse array")
  
  local mixedTable = {name = "test", 1, 2, 3}
  assertEqual("[1,2,3]", json.encode(mixedTable), "Encoding table with both array and object properties (should encode as array)")
  
  local nonStringKeys = {[true] = 1, [false] = 2}
  assertEqual("{}", json.encode(nonStringKeys), "Encoding object with non-string keys (should be empty object)")
  
  local specialString = json.encode("\0\1\2\3\4\5\6\7\8\9\10\11\12\13\14\15\16\17\18\19")
  assertEqual(true, #specialString > 0, "Encoding control characters shouldn't fail")
  
  local infinityResult = json.encode(1/0)
  local nanResult = json.encode(0/0)
  assertEqual(true, infinityResult == "null" or tonumber(infinityResult), "Encoding Infinity should output null or a number")
  assertEqual(true, nanResult == "null" or tonumber(nanResult) ~= tonumber(nanResult), "Encoding NaN should output null or NaN")
  
  -- Test 45-48: Performance test for large structures
  local largeArray = {}
  for i = 1, 1000 do
    largeArray[i] = i
  end
  local largeArrayJson = json.encode(largeArray)
  assertEqual(true, largeArrayJson:sub(1, 1) == "[" and largeArrayJson:sub(-1) == "]", "Encoding large array")
  assertEqual(1000, select(2, largeArrayJson:gsub(",", ",")) + 1, "Large array should contain 1000 elements")
  
  local largeObject = {}
  for i = 1, 1000 do
    largeObject["key" .. i] = i
  end
  local largeObjectJson = json.encode(largeObject)
  assertEqual(true, largeObjectJson:sub(1, 1) == "{" and largeObjectJson:sub(-1) == "}", "Encoding large object")
  assertEqual(1000, select(2, largeObjectJson:gsub(",", ",")) + 1, "Large object should contain 1000 elements")
  
  -- Print summary
  print("\nTest Summary:")
  print("  Total:  " .. (passCount + failCount))
  print("  Passed: " .. passCount)
  print("  Failed: " .. failCount)
  
  if failCount > 0 then
    print("\nFailed tests:")
    for _, testName in ipairs(failures) do
      print("  - " .. testName)
    end
  end
  
  return passCount, failCount
end

-- Run the tests
runTests()