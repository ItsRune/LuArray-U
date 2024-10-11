local Array = require("../src/init")

local numArr = Array.new(0, 100, 10, 1000, 5000)
local strArr = Array.new("Hello", "Sort", "Me", "Please")

numArr:toSorted():forEach(function(a)
    print(a)
end)

strArr:toSorted():forEach(function(a)
    print(a)
end)
