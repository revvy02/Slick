local Cleaner = require(script.Parent.Parent.Cleaner)
local Promise = require(script.Parent.Parent.Promise)

local Card = require(script.Parent.Card)
local Signal = require(script.Parent.Signal)

--[=[
    Keeper class that tracks and holds card instances

    @class Keeper
]=]
local Keeper = {}
Keeper.__index = Keeper

--[=[
    Creates a new Keeper object

    @function new
    @within Keeper
]=]
function Keeper.new()
    local self = setmetatable({}, Keeper)

    self._cleaner = Cleaner.new()

    self.added = self._cleaner:add(Signal.new())
    self.removed = self._cleaner:add(Signal.new())
    self.changed = self._cleaner:add(Signal.new())

    return self
end

--[=[
    Checks whether or not the passed argument is a Keeper instance or not

    @param obj any
    @return bool
]=]
function Keeper.is(obj)
    return type(obj) == "table" and getmetatable(obj) == Keeper
end

--[=[
    Gets the card from the key

    @param key any
    @return Card | nil
]=]
function Keeper:getCard(key)
    return self._cleaner:get(key)
end

--[=[
    Creates the card and fires keyAdded or throws if it exists

    @param key any
    @param value? any
    @return Card
]=]
function Keeper:addCard(key, value)
    assert(not self._cleaner:get(key), string.format("%s already exists as a card", tostring(key)))

    local card = self._cleaner:set(key, Card.new(value))
    card.key = key

    print("aaaa", card)
    self.added:fire(key, card)

    self._cleaner:set(card, card:getChangedSignal():connect(function(newValue, oldValue)
        self.changed:fire(card, newValue, oldValue)
    end))

    return card
end

--[=[
    Removes the key and fires keyRemoved or throws if it doesn't exist

    @param key any
    @return Card
]=]
function Keeper:removeCard(key)
    assert(self._cleaner:get(key), string.format("%s does not exist as a card", tostring(key)))

    local card = self._cleaner:finalize(key)

    self._cleaner:finalize(card)

    self.removed:fire(key, card)

    return card
end

--[=[
    Destroys the keeper and sets destroyed field to true (preps for garbage collection)

    @return nil
]=]
function Keeper:destroy()
    assert(not self.destroying and not self.destroyed, "Keeper already destroyed")

    self.destroying = true
    self._cleaner:destroy()
    self.destroying = false
    self.destroyed = true
end

return Keeper