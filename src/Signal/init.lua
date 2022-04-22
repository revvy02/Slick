local Connection = require(script.Connection)
local Promise = require(script.Parent.Parent.Promise) -- packages will be siblings in the datamodel

--[[
    "thread recycling" from Stravant's GoodSignal implementation
]]
local freeRunnerThread = nil

local function acquireRunnerThreadAndCallEventHandler(fn, ...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	-- The handler finished running, this runner thread is free again.
	freeRunnerThread = acquiredRunnerThread
end

local function runEventHandlerInFreeThread(...)
	acquireRunnerThreadAndCallEventHandler(...)
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

local function eachNode(node, fn, ...)
    while node do
        fn(node, ...)
        node = node._next
    end
end

local function fireDeferred(node, ...)
    task.defer(node._fn, ...)
end

local function fireImmediate(node, ...)
    if not freeRunnerThread then
        freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
    end
    
    task.spawn(freeRunnerThread, node._fn, ...)
end

--[=[
    Signal implementation in Luau based off of Stravant's GoodSignal.

    @class Signal
]=]
local Signal = {}
Signal.__index = Signal

--[=[
    Calls the deactivated callback if the conditions for it are right

    @private
    @return bool
]=]
function Signal:_tryDeactivatedCall()
    local onDeactivated = self._onDeactivated

    if onDeactivated and self._head == nil then
        onDeactivated()

        return true
    end

    return false
end

--[=[
    Calls the activated callback if the conditions for it are right

    @private
    @return bool
]=]
function Signal:_tryActivatedCall()
    local onActivated = self._onActivated

    if onActivated and self._head and not self._head._next then
        onActivated()

        return true
    end

    return false
end


--[=[
    Constructs a new signal object.

    @function new
    @within Signal
    @return Signal
]=]
function Signal.new()
    local self = setmetatable({
        --[=[
            Tells whether the signal is in deferred mode or not

            @prop deferred boolean
            @readonly
            @within Signal
        ]=]
        deferred = false,

        --[=[
            Tells whether the signal is currently queueing fired arguments or not

            @prop queueing boolean
            @readonly
            @within Signal
        ]=]
        queueing = false,

        --[=[
            Tells whether or not the signal is currently firing arguments or not
            (this should only be true if the environment it is being read from is within a handler call)
        ]=]
        firing = false,

        _head = nil,
        _onActivated = nil,
        _onDeactivated = nil,
    }, Signal)

    return self
end

--[=[
    Returns whether the passed argument is a signal

    @param obj any
    @return boolean
]=]
function Signal.is(obj)
    return type(obj) == "table" and getmetatable(obj) == Signal or false
end

--[=[
    Enables argumenting queuing from fire calls when there are no connections and sets queueing to true

    @return nil
]=]
function Signal:enableQueueing()
    if not self.queueing then
        self._queue = {}
        self.queueing = true
    end
end

--[=[
    Disables argumenting queuing from fire calls when there are no connections and sets queueing to false

    @return nil
]=]
function Signal:disableQueueing()
    if self.queueing then
        self._queue = nil
        self.queueing = false
    end
end

--[=[
    Enables deferred signaling and sets deferred to true

    @return nil
]=]
function Signal:enableDeferred()
    if not self.deferred then
        self.deferred = true
    end
end

--[=[
    Disables deferred signaling and sets deferred to false

    @return nil
]=]
function Signal:disableDeferred()
    if self.deferred then
        self.deferred = false
    end
end

--[=[
    Sets the callback that is called when a connection is made from when there are no connections (an activated state enters).

    @param fn function
    @return nil
]=]
function Signal:setActivatedCallback(fn)
    self._onActivated = fn
end

--[=[
    Sets the callback that is called when the last active connection is disconnected (a deactivated state enters).

    @param fn function
    @return nil
]=]
function Signal:setDeactivatedCallback(fn)
    self._onDeactivated = fn
end

--[=[
    Fires the signal with the optional passed arguments. This method makes optimizations by recycling threads in cases where connections don't yield if deferred is false.

    @param ... any
    @return nil
]=]
function Signal:fire(...)
    local head = self._head

    if head == nil then
        if self.queueing then
            table.insert(self._queue, table.pack(...))
        end
    else
        self.firing = true

        eachNode(head, self.deferred and fireDeferred or fireImmediate, ...)

        local newHead, newTail

        eachNode(head, function(node)
            if node.connected then
                if not newHead then
                    head = node
                    newTail = node
                else
                    newTail._next = node
                    newTail = node
                end
            end
        end)
        
        self._head = newHead
        self.firing = false

        self:_tryDeactivatedCall()
    end
end

--[=[
    Empties any queued arguments that may have been added when fire was called with no connections.

    @return nil
]=]
function Signal:flush()
    if self.queueing then
        table.clear(self._queue)
    end
end

--[=[
    Yields the current thread until the signal is fired and returns what was fired

    @yields
    @return any
]=]
function Signal:wait()
	local thread = coroutine.running()
	local connection
    
    connection = self:connect(function(...)
		connection:disconnect()
		task.spawn(thread, ...)
	end)

	return coroutine.yield()
end

--[=[
    Wraps a wait call in a promise. This is preferred over calling wait directly.

    @return Promise
]=]
function Signal:promise()
    return Promise.try(function()
        return self:wait()
    end)
end

--[=[
    Connects a handler function to the signal so that it can be called when it's fired.

    @param fn function
    @return Connection
]=]
function Signal:connect(fn)
    local connection = Connection.new(self, fn)
    local head = self._head

    connection._next = head
    self._head = connection

    if not head then
        self:_tryActivatedCall()

        if self.queueing then
            for _, args in pairs(self._queue) do
                fn(table.unpack(args))
            end

            self:flush()
        end
    end

    return connection
end

--[=[
    Connects a handler function to the signal so that it can be called when it's fired only once

    @param fn function
    @return Connection
]=]
function Signal:once(fn)
    local connection
    
    connection = self:connect(function(...)
        if connection.connected then
            connection:disconnect()
            fn(...)
        end
    end)

    return connection
end

--[=[
    Disconnects all connections

    @return nil
]=]
function Signal:disconnectAll()
    local onDeactivated = self._onDeactivated
    local head = self._head
    local node = head

    while node do
        node.connected = false
        node = node._next
    end

    if head and onDeactivated then
        onDeactivated()
    end

    self._head = nil
end

--[=[
    Disconnects all connections and sets the "destroyed" field to true

    @return nil
]=]
function Signal:destroy()
    assert(not self.destroying and not self.destroyed, "Signal is already destroyed")

    self.destroying = true
    self:disconnectAll()
    self.destroying = false

    self.destroyed = true
end

--[[
    Include PascalCase RbxScriptSignal interface
]]
Signal.Destroy = Signal.destroy
Signal.Wait = Signal.wait
Signal.Connect = Signal.connect
Signal.DisconnectAll = Signal.disconnectAll

return Signal