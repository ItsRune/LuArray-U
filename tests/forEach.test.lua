local Array = require("@Array")

local arr = Array(3)
local arr2 = Array.new(6)
local arr3 = Array.new("Hello,", " ", "World!")

arr:forEach(print)
print("------------------------")
arr2:forEach(print)

--[[
Empty 1 table: tableAddr
Empty 2 table: tableAddr
Empty 3 table: tableAddr
Empty 4 table: tableAddr
Empty 5 table: tableAddr
Empty 6 table: tableAddr
]]
print("------------------------")
arr3:forEach(print)
