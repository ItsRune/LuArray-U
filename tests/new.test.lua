local Array = require("@Array")

local arr = Array(3)
local arr2 = Array.new(1)
local arr3 = Array.new("Hello,", " ", "World!", "TEST")

print(arr.Length, typeof(arr)) --> 3 table
print(arr2.Length, typeof(arr2)) --> 1 table
print(arr3.Length, typeof(arr3)) --> 4 table
