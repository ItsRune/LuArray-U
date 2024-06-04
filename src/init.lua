export type arrayPriv<T> = {
	__len: (self: arrayPriv<T>) -> number,
	__newindex: (self: arrayPriv<T>, index: number, value: T) -> (),
	__index: (self: arrayPriv<T>, index: any) -> any,
	__iter: (self: arrayPriv<T>) -> { T },

	Length: number,

	_data: { T },
	_isArray: true,
}

export type arrayPub = {
	new: (...any) -> arrayPriv<any>,
	isArray: (array: any?) -> boolean,
	from: (item: { any }, callback: (data: any) -> any) -> arrayPriv<any>,
}

--[=[
	@class Array
	A data structure with multiple JavaScript-like methods attached to it.
]=]
--
local Array = {}
local Class = {}

local isRobloxEnvironment, arrayIteratorModule = pcall(function()
	return script.ArrayIterator
end)

local ArrayIterator = require(isRobloxEnvironment and arrayIteratorModule or "ArrayIterator")

--// Array Metamethods \\--
Class.__len = function(self: arrayPriv<any>)
	return #self._data
end
Class.__newindex = function(self: arrayPriv<any>, index: number?, value: any?)
	if typeof(index) ~= "number" or value == nil then
		rawset(self, index, value)
		return
	end

	rawset(self._data, index, value)
end
Class.__index = function(self: arrayPriv<any>, index: number?)
	if rawget(self, index) == nil and typeof(index) == "number" and self["_data"] ~= nil then
		return rawget(self._data, index)
	end

	local isOk, result = pcall(rawget, Class, index)
	if not isOk then
		return nil
	end

	return result
end
Class.__iter = function(self: arrayPriv<any>)
	return self._data
end

--// Public Functions \--
--[=[
	Creates a new Array with force if needed, eliminating the length of an array from being used when `true`.
	@param _forceCreation boolean
	@param ... T
	@return Array<T>

	@since 1.0.0
	@within Array
]=]
--
function Array._new<T>(_forceCreation: boolean?, ...: T): arrayPriv<T>
	local self = setmetatable({}, Class)
	local Data = { ... }
	local isDataLengthOfArray = (#Data == 1 and typeof(Data[1]) == "number" and not _forceCreation)

	-- Public --
	self.Length = isDataLengthOfArray and Data[1] or #Data

	-- Private --
	self._data = isDataLengthOfArray and table.create(Data[1]) or { ... }
	self._isArray = true

	return self
end

--[=[
	Creates a new Array.
	@param ... T
	@return Array<T>

	@since 1.0.0
	@within Array
]=]
--
function Array.new<T>(...: T): arrayPriv<T>
	return Array._new(false, ...)
end

--[=[
	Checks if the passed argument is a valid `Array` object.
	@param array Array<T>
	@return boolean

	@since 1.0.0
	@within Array
]=]
--
function Array.isArray<T>(array: arrayPriv<T>): boolean
	return (typeof(array) == "table" and array["_isArray"] == true)
end

--[=[
	Creates a new Array from a single argument, allowing for a callback IF the argument supplied is a lua table.
	@param item T
	@return Array<T>

	@since 1.0.0
	@within Array
]=]
--
function Array.from<T>(item: T): arrayPriv<T>
	if typeof(item) == "string" then
		item = string.split(item, "")
	elseif typeof(item) == "number" then
		item = { item }
	else
		return Array.new(0)
	end

	return Array._new(true, table.unpack(item))
end

--[=[
	Creates a new Array from a variable number of arguments.
	@param ... T
	@return Array<T>

	```lua
	local myArray = Array.of("foo", "bar", 2, false, true, 6)
	print(myArray[2]) -- "bar"
	```

	@since 1.0.0
	@within Array
]=]
--
function Array.of<T>(...: T): arrayPriv<T>
	return Array._new(true, ...)
end

--// Private Functions \--
--[=[
	Main loop handler for changing data within the Array.
	@param Callback (data: T, index: number, array: { T }) -> T
	@return (T?, number?, { T }?)

	@tag Chainable
	@since 1.0.0
	@within Array
	@private
]=]
--
function Class:_changeLoop<T>(Callback: (data: T, index: number, array: { T }) -> T): (T, number, { T })
	for index: number = 1, #self._data do
		local value = self._data[index]
		local newValue = Callback(value, index, self._data)

		if newValue == nil then
			newValue = value
		end

		self._data[index] = value
	end

	return self
end

--[=[
	Main loop handler for filtering data within the Array.
	@param Callback (data: T, index: number, array: { T }) -> T
	@return Array<T>

	@tag Chainable
	@since 1.0.0
	@within Array
	@private
]=]
--
function Class:_filterLoop<T>(Callback: (data: T, index: number, array: { T }) -> T): arrayPriv<T>
	local filtered = {}

	for index: number = 1, #self._data do
		local value = self._data[index]
		local shouldBeFiltered = Callback(value, index, self._data)

		if shouldBeFiltered then
			table.insert(filtered, #filtered + 1, value)
		end
	end

	self.Length = #filtered
	self._data = filtered

	return self
end

--[=[
	Main loop handler for filtering data within the Array.
	@param reversed boolean
	@param Callback (data: T, index: number, array: { T }) -> T
	@return (T?, number?, { T }?)

	@since 1.0.0
	@within Array
	@private
]=]
--
function Class:_findLoop<T>(
	reversed: boolean,
	Callback: (data: T, index: number, array: { T }) -> T
): (T?, number?, { T }?)
	if reversed then
		for index: number = #self._data, 1, -1 do
			local value = self._data[index]
			local isFound = Callback(value, index, self._data)

			if isFound then
				return value, index, self._data
			end
		end
		return
	end

	for index: number = 1, #self._data do
		local value = self._data[index]
		local isFound = Callback(value, index, self._data)

		if isFound then
			return value, index, self._data
		end
	end
end

--[=[
	Swaps the `first` and `second` indices within the array.
	@param first number
	@param second number
	@return ()

	@since 1.0.0
	@private
	@within Array
]=]
--
function Class:_swap(first: number, second: number): ()
	assert(first and second, "Please specify which two indices you'd like to swap.")

	local firstValue = self._data[first]
	local secondValue = self._data[second]

	self._data[first] = secondValue
	self._data[second] = firstValue
end

--[=[
	Returns the pivot index of the array
	@param Start number
	@param End number
	@param Callback (data: T, index: number, array: { T }) -> boolean
	@return number

	@since 1.0.0
	@private
	@within Array
]=]
--
function Class:_partition<T>(
	Start: number,
	End: number,
	Callback: (data: T, index: number, array: { T }) -> boolean
): arrayPriv<T>
	local pivot = self._data[End]
	local sortingIndex = Start - 1

	for index = Start, End do
		if not Callback(self._data[index], pivot) then
			continue
		end

		sortingIndex += 1
		self:_swap(sortingIndex, index)
	end

	sortingIndex += 1
	self:_swap(sortingIndex, End)

	return sortingIndex
end

--[=[
	Sorts the array with the QuickSort algorithm.
	@param Start number
	@param End number
	@param Callback (data: T, index: number, array: { T }) -> boolean
	@return ()

	@since 1.0.0
	@private
	@within Array
]=]
--
function Class:_quickSort<T>(Start: number, End: number, Callback: (data: T, index: number, array: { T }) -> boolean): ()
	if End <= Start then
		return
	end

	local pivot = self:_partition(Start, End, Callback)
	self:_quickSort(Start, pivot - 1, Callback)
	self:_quickSort(pivot + 1, End, Callback)
end

--[=[
	Creates a new Array from a variable number of arguments.
	@param Callback (data: T, index: number, array: { T }) -> K
	@return Array

	```lua
	local myArray = Array.new(1,2,3,4)
	myArray:map(function(x: number)
		return x * 2
	end)
	```

	@tag Chainable
	@since 1.0.0
	@within Array
]=]
--
function Class:map<T, K>(Callback: (data: T, index: number, array: { T }) -> K): arrayPriv<T>
	if not Callback then
		return self._data
	end

	local newArray = Array.new(table.unpack(self._data))
	newArray:_changeLoop(Callback)

	return newArray
end

--[=[
	Returns a new Array that was recursively concatenated with all sub-array/tables within the Array until the depth is reached.
	@param depth number?
	@return Array

	```lua
	local myArray = Array.new(1, {2, {3, 4}})
	myArray:flat() -- Array [ 1, 2, Array [ 3, 4 ] ]
	```

	@tag Chainable
	@since 1.0.0
	@within Array
]=]
--
function Class:flat<T>(depth: number?): arrayPriv<T>
	depth = depth or 1
	local newArray = Array._new(true, table.unpack(self._data))

	for i = 1, self.Length do
		local value = self._data[i]
		if typeof(value) ~= "table" then
			continue
		end

		local data = value
		if Array.isArray(value) then
			data = value._data
		end

		for j = 1, #data do
			table.insert(self._data, #self._data + 1, data[j])
			self.Length += 1
		end
		break
	end

	depth -= 1
	if depth == 0 then
		return self
	end

	return self:flat(depth)
end

--[=[
	I don't know how to explain this, [but mdn web docs do it best.](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/reduce)
	@param Callback (accumulator: T, currentValue: T) -> K
	@param initialValue K?
	@return K

	```lua
	local myArray = Array.new(1, 2, 3, 4)
	local initialValue = 0
	print(
		myArray:reduce(
			function(accumulator: number, value: number)
				return accumulator + value
			end,
			initialValue
		)
	) --> 10
	```

	@tag Chainable
	@since 1.0.0
	@within Array
]=]
--
function Class:reduce<T, K>(Callback: (accumulator: T, currentValue: T) -> K, initialValue: K?): K
	local _mem = initialValue or 0

	self:forEach(function(data: T)
		_mem = Callback(_mem, data)
	end)

	return _mem
end

--[=[
	
	@param Callback (data: T, index: number, array: { T }) -> K
	@return Array

	```lua
	local myArray = Array.new(1,2,3,4)
	myArray:map(function(x: number)
		return x * 2
	end)
	```

	@tag Chainable
	@since 1.0.0
	@within Array
]=]
--

--[=[
	Creates a new Array from a variable number of arguments.
	@param Callback (data: T, index: number, array: { T }) -> boolean
	@return boolean

	```lua
	local myArray = Array.new(1, 2, 3, 4, 5)

	if
		myArray:some(
			function(x: number)
				return x == 3
			end
		)
	then
		print("Good!")
	end
	```

	@since 1.0.0
	@within Array
]=]
--
function Class:some<T>(Callback: (data: T, index: number, array: { T }) -> boolean): boolean
	if not Callback then
		return false
	end

	for index: number = 1, #self._data do
		local value = self._data[index]
		local exists = Callback(value, index, self._data)

		if exists then
			return true
		end
	end

	return false
end

--[=[
	Filters the array with the given callback function and returns the filtered table.

	```lua
	local myArray = Array.new(1, 2, 3, 4, 5)
	local filtered = myArray:filter(function(x: number)
		return x > 3
	end) -- { 4, 5 }
	```

	@since 1.0.0
	@within Array
]=]
--
function Class:filter<T>(Callback: (data: T, index: number, array: { T }) -> boolean): arrayPriv<T>
	local newArray = Array.new(table.unpack(self._data))
	newArray:_filterLoop(Callback)

	local data = newArray._data
	newArray:Destroy()

	return data
end

--[=[
	Finds a singular value within the array and returns it.
	@param Callback (data: T, index: number, array: { T }) -> boolean
	@return T?

	```lua
	local myArray = Array.new(5, 12, 50, 130, 44)
	local filtered = myArray:find(function(x: number)
		return x > 3
	end) -- 4
	```

	@since 1.0.0
	@within Array
]=]
--
function Class:find<T>(Callback: (data: T, index: number, array: { T }) -> boolean): T?
	local value, index, _ = self:_findLoop(false, Callback)
	return value
end

--[=[
	Finds a singular index within the array and returns it.
	@param Callback (data: T, index: number, array: { T }) -> boolean
	@return (T?, number?)

	```lua
	local myArray = Array.new(5, 12, 50, 130, 44)
	local filtered = myArray:findIndex(function(x: number)
		return x > 3
	end) -- 4, 4
	```

	@since 1.0.0
	@within Array
]=]
--
function Class:findIndex<T>(Callback: (data: T, index: number, array: { T }) -> boolean): (T?, number?)
	local value, index, _ = self:_findLoop(false, Callback)
	return index
end

--[=[
	Finds a singular value within the array starting from the end and returns it.
	@param Callback (data: T, index: number, array: { T }) -> boolean
	@return T?

	```lua
	local myArray = Array.new(5, 12, 50, 130, 44)
	print(myArray:findLast(function(x: number)
		return x > 3
	end)) -- 44
	```

	@since 1.0.0
	@within Array
]=]
--
function Class:findLast<T>(Callback: (data: T, index: number, array: { T }) -> boolean): (T?, number?)
	local value, index, _ = self:_findLoop(true, Callback)
	return value
end

--[=[
	Finds a singular index within the array starting from the end and returns it.
	@param Callback (data: T, index: number, array: { T }) -> boolean
	@return number?

	```lua
	local myArray = Array.new(5, 12, 50, 130, 44)
	print(myArray:findLastIndex(function(x: number)
		return x > 45
	end)) -- 4 | Array[4] = 130
	```

	@since 1.0.0
	@within Array
]=]
--
function Class:findLastIndex<T>(Callback: (data: T, index: number, array: { T }) -> boolean): (T?, number?)
	local value, index, _ = self:_findLoop(true, Callback)
	return index
end

--[=[
	Finds a singular value within the array and returns it's information.
	@param item T
	@return boolean

	```lua
	local myArray = Array.new("dog", "duck", "cat", "bird")
	local hasCat = myArray:includes("cat") -- true
	local hasAlligator = myArray:includes("alligator") -- false
	```

	@since 1.0.0
	@within Array
]=]
--
function Class:includes<T>(item: T): boolean
	local value = self:find(function(data: T)
		return item == data
	end)

	return (value ~= nil)
end

--[=[
	Splits the array up into a portion selected by the `Start` and `End` parameters.
	@param Start number?
	@param End number?
	@return { T }

	```lua
	local myArray = Array.new("ant", "bison", "camel", "duck", "elephant")
	local sliced = myArray:slice(3, -1) -- { "camel", "duck" }
	```

	@since 1.0.0
	@within Array
]=]
--
function Class:slice<T>(Start: number?, End: number?): arrayPriv<T>
	local data = self._data
	local newData = {}

	local startType = typeof(Start)
	local endType = typeof(End)

	if startType == "number" and not End then
		local uptoValue = (Start < 0) and #self._data + Start or Start
		return self:filter(function(_, index: number)
			return index >= uptoValue
		end)
	elseif startType == "number" and endType == "number" then
		local firstIndex = (Start < 0) and #self._data + Start or Start
		local lastIndex = (End < 0) and #self._data + End or End

		return self:filter(function(_, index: number)
			return index >= firstIndex and index <= lastIndex
		end)
	end

	return self._data
end

--[=[
	Performs a for loop on the array with a given callback which doesn't affect any entries.
	@param Callback Callback: (data: T, index: number, array: { T }) -> ()
	@return Array<T>

	```lua
	local myArray = Array.new("ant", "bison", "camel", "duck", "elephant")
	myArray:forEach(print)
	```

	@tag Chainable
	@since 1.0.0
	@within Array
]=]
--
function Class:forEach<T>(Callback: (data: T, index: number, array: { T }) -> ()): ()
	for index: number = 1, #self._data do
		local value = self._data[index]
		Callback(value, index, self._data)
	end

	return self
end

--[=[
	Performs a test on every element within the array to ensure they all pass.
	@param Callback Callback: (data: T, index: number, array: { T }) -> boolean
	@return boolean

	```lua
	local myArray = Array.new("ant", "bison", "camel", "duck", "elephant")
	myArray:every(function(animal: string)
		return string.len(animal) > 2
	end) -- true
	```

	@since 1.0.0
	@within Array
]=]
--
function Class:every<T>(Callback: (data: T, index: number, array: { T }) -> boolean): boolean
	for index: number = 1, #self._data do
		local value = self._data[index]
		local isOk = Callback(value, index, self._data)

		if not isOk then
			return false
		end
	end

	return true
end

--[=[
	Adds new element(s) onto the end of the array.

	```lua
	local myArray = Array.new("ant", "bison", "camel", "duck", "elephant")
	myArray:push("duck", "elephant") -- { "ant", "bison", "camel", "duck", "elephant", "duck", "elephant" }
	```

	@since 1.0.0
	@within Array
]=]
--
function Class:push<T>(...: T): arrayPriv<T>
	local dataToAdd = { ... }
	for i = 1, #dataToAdd do
		table.insert(self._data, #self._data + 1, dataToAdd[i])
	end

	self.Length += #dataToAdd
end

--[=[
	Removes the last element within the array and returns whatever it's value is.
	@return T

	```lua
	local myArray = Array.new("ant", "bison", "camel", "duck", "elephant")
	myArray:pop() -- "elephant"
	myArray:pop() -- "duck"
	```

	@since 1.0.0
	@within Array
]=]
--
function Class:pop<T>(): T
	local poppedValue = table.remove(self._data, #self._data)
	self.Length -= 1

	return poppedValue
end

--[=[
	Uses QuickSort under the hood to complete this operation, if you'd like to use it directly with specifying a `start` and `end` indices please use `Array:_quickSort`
	@param Callback ((a: T, b: T) -> boolean)?
	@return Array<T>

	```lua
	local myArray = Array.new("ant", "bison", "camel", "duck", "elephant")
	myArray:sort(function(first: string, second: string)
		local firstChar, secondChar = string.sub(first, 1, 1), string.sub(second, 1, 1)
		return string.byte(firstChar) > string.byte(secondChar)
	end) --> "elephant", "duck", "camel", "bison", "ant"
	```

	@tag Chainable
	@since 1.0.0
	@within Array
]=]
--
function Class:sort<T>(Callback: ((a: T, b: T) -> boolean)?): arrayPriv<T>
	if not Callback then
		Callback = function(a: any, b: any)
			local str1, str2 = tostring(a), tostring(b)
			local char1, char2 = string.sub(str1, 1, 1), string.sub(str2, 1, 1)
			return string.byte(char1) < string.byte(char2)
		end
	end

	self:_quickSort(1, self.Length, Callback)
	return self
end

--[=[
	Removes the last element within the array and returns whatever it's value is.

	```lua
	local myArray = Array.new("ant", "bison", "camel", "duck", "elephant")
	myArray:pop() -- "elephant"
	myArray:pop() -- "duck"
	```

	:::warning
	This method mutates the original array, please use `toReversed()` if you'd prefer this method without mutations.
	:::

	@tag Chainable
	@since 1.0.0
	@within Array
]=]
--
function Class:reverse<T>(): { T }
	local newData = table.create(self.Length)

	local arrayLength = self.Length
	for i = arrayLength, 1, -1 do
		newData[(arrayLength + 1) + (i * -1)] = self._data[i]
	end

	self._data = newData
	return self
end

--[=[
	Changes the contents within the array by removing/replacing/adding new elements.
	@param index number
	@param deleteCount number
	@param ... T
	@return Array<T>

	```lua
	local myArray = Array.new("ant", "bison", "camel", "duck", "elephant")
	myArray:splice(1, 1, "spider")
	print(myArray[1]) -- "spider"
	```

	@tag Chainable
	@since 1.0.0
	@within Array
]=]
--
function Class:splice<T>(index: number, deleteCount: number, ...: T): arrayPriv<T>
	local toReplaceWith = { ... }

	if index > self.Length then
		return
	end

	for i = index, self.Length do
		table.remove(self._data, i)
		self.Length -= 1

		for j = 1, #toReplaceWith do
			self.Length += 1
			table.insert(self._data, (i - 1) + j, toReplaceWith[j])
		end

		deleteCount -= 1
		if deleteCount == 0 then
			break
		end
	end

	return self
end

--[=[
	Changes all elements within the array with a static value at a given start position.
	@param ... any
	@return Array<T>

	```lua
	local myArray = Array.new(1, 2, 3, 4)
	myArray:fill(0, 2, 4) --> 1, 2, 0, 0
	myArray:fill(5, 1) --> 1, 5, 5, 5
	myArray:fill(4) --> 4, 4, 4, 4
	```

	@tag Chainable
	@since 1.0.0
	@within Array
]=]
--
function Class:fill<T>(...: any): arrayPriv<T>
	local Data = { ... }
	local Start = (tonumber(Data[2]) ~= nil) and Data[2] + 1 or 1
	local End = (tonumber(Data[3]) ~= nil) and Data[3] or self.Length
	local toReplaceWith = Data[1]

	for i = Start, End do
		self._data[i] = toReplaceWith
	end

	return self
end

--[=[
	Returns the internal table that holds all the values.
	@return { T }

	```lua
	local myArray = Array.new(1, 2, 3, 4)
	print(myArray:values()) --> { 1, 2, 3, 4 }
	```

	@since 1.0.0
	@within Array
]=]
--
function Class:values<T>(): { T }
	return self._data
end

--[=[
	Returns an iterator object that contains the key/value pairs for each array index.
	@return ArrayIterator<T>

	```lua
	local myArray = Array.new("ant", "bison", "camel")
	local myIterator = myArray:entries()
	print(myIterator:next().Value) --> Array [ 1, "ant" ]
	print(myIterator:next().Value) --> Array [ 2, "bison" ]
	```

	@since 1.0.0
	@within Array
]=]
--
function Class:entries<T>(): arrayIter<T>
	return ArrayIterator.new(self, Array)
end

--[=[
	Returns a new Array after `splice` has been invoked.
	@param index number
	@param deleteCount number
	@param ... T
	@return Array<T>

	@since 1.0.0
	@within Array
]=]
--
function Class:toSpliced<T>(index: number, deleteCount: number, ...: T): arrayPriv<T>
	local newArray = Array._new(true, table.unpack(self._data))
	newArray:splice(index, deleteCount, ...)

	return newArray
end

--[=[
	Returns a new Array after `reverse` has been invoked.
	@return Array<T>

	@since 1.0.0
	@within Array
]=]
--
function Class:toReversed<T>(): arrayPriv<T>
	local newArray = Array._new(true, table.unpack(self._data))
	newArray:reverse()

	return newArray
end

--[=[
	Returns a new Array after `sort` has been invoked.
	@param Callback ((a: T, b: T) -> boolean)?
	@return Array<T>

	@since 1.0.0
	@within Array
]=]
--
function Class:toReversed<T>(Callback: ((a: T, b: T) -> boolean)?): arrayPriv<T>
	local newArray = Array._new(true, table.unpack(self._data))
	newArray:sort(Callback)

	return newArray
end

--[=[
	Provides the index starting from the back of the Array. This will return `nil` if no value is present.
	@param item any
	@return number?

	@since 1.0.0
	@within Array
]=]
--
function Class:lastIndexOf<T>(item: any): arrayPriv<T>
	for i = self.Length, 1, -1 do
		if self._data[i] == item then
			return self.Length - i
		end
	end
	return nil
end

--[=[
	Clears the Array and prepares it for garbage collection.
	@return nil

	```lua
	local myArray = Array.new("ant", "bison", "camel", "duck", "elephant")
	myArray:Destroy() -- Once used this can't be used again.
	```

	@since 1.0.0
	@within Array
]=]
--
function Class:Destroy()
	table.clear(self)
	setmetatable(self, nil)
	self = nil
end

--[=[
	Temporary method to print the result into the output.

	@ignore
	@since 1.0.0
	@within Array
]=]
--
function Class:debugPrint()
	print("------------------------------")
	self:forEach(print)
end

local myArr = Array.new("ant", "bison", "camel", "duck", "elephant")

-- print(myArr
-- 	:Map(function(x: string)
-- 		return string.len(x)
-- 	end)
-- 	:debugPrint())

-- print(table.concat(
-- 	myArr:Filter(function(x: string)
-- 		return string.len(x) == 4
-- 	end),
-- 	", "
-- ))

-- print(myArr:reverse():debugPrint())

-- myArr:sort(function(first: string, second: string)
-- 	local firstChar, secondChar = string.sub(first, 1, 1), string.sub(second, 1, 1)
-- 	return string.byte(firstChar) > string.byte(secondChar)
-- end) --> "elephant", "duck", "camel", "bison", "ant"

-- myArr:splice(2, 1, "spider")

-- local myArray = Array.new(1, 2, 3, 4)

-- print(myArray:reduce(function(acc, val)
-- 	return acc + val
-- end))

-- myArray:debugPrint()
-- myArray:fill(0, 2, 4) --> 1, 2, 0, 0
-- myArray:debugPrint()
-- myArray:fill(5, 1) --> 1, 5, 5, 5
-- myArray:debugPrint()
-- myArray:fill(6) --> 6, 6, 6, 6
-- myArray:debugPrint()

-- local iterator = myArr:entries()
-- iterator.Value:debugPrint()
-- iterator:Next().Value:debugPrint()
-- iterator:Next().Value:debugPrint()
-- iterator:Next().Value:debugPrint()
-- iterator:Next().Value:debugPrint()

-- myArr:debugPrint()
--// Return \--
return Array :: arrayPub
