--[=[
	@class ArrayIterator
	A class that represents an iteration of an [Array](/api/Array).
]=]
--
local ArrayIterator = {}
local Class = {}
Class.__index = Class

export type arrayIter<T> = {
	Value: T,

	Next: () -> arrayIter<T>,
	Previous: () -> arrayIter<T>,
}

--// Public Functions \\--
--[=[
	Creates a new iterator for the array.
	@param existingArray Array<T>
	@return ArrayIterator<T>

	@since 1.0.0
	@within ArrayIterator
]=]
--
function ArrayIterator.new<T>(existingArray: { T }, arrayModule: { any }): arrayIter<T>
	local self = setmetatable({}, Class)

	self._arrMod = arrayModule -- This is probably a bad idea.
	self._array = existingArray
	self._ptr = 1
	self.Value = { 0, -1 }

	self:_generate()
	return self
end

--// Private Functions \\--
--[=[
	Increases the pointer forward an index.
	@return ArrayIterator<T>

	@tag Chainable
	@since 1.0.0
	@within ArrayIterator
]=]
--
function Class:Next<T>(): arrayIter<T>
	self._ptr = math.clamp(self._ptr + 1, 1, self._array.Length)
	self:_generate()
	return self
end

--[=[
	Decreases the pointer forward an index.
	@return ArrayIterator<T>

	@tag Chainable
	@since 1.0.0
	@within ArrayIterator
]=]
--
function Class:Previous<T>(): arrayIter<T>
	self._ptr = math.clamp(self._ptr - 1, 1, self._array.Length)
	self:_generate()
	return self
end

--[=[
	Generates the `.Value` property of the iterator.
	@return ()

	@since 1.0.0
	@private
	@within ArrayIterator
]=]
--
function Class:_generate(): ()
	local index = self._ptr
	local value = self._array[index]

	if self._arrMod.isArray(self.Value) then
		self.Value:Destroy()
	end

	self.Value = self._arrMod.new(index, value)
end

return ArrayIterator
