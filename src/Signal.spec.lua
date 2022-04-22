return function()
    local RunService = game:GetService("RunService")

    local Signal = require(script.Parent.Signal)
    local Promise = require(script.Parent.Parent.Promise)

    local empty = {}

    local function noop()

    end

    describe("Signal.new", function()
        it("should create a new signal object", function()
            local signal = Signal.new()

            expect(signal).to.be.ok()
            expect(signal.is(signal)).to.equal(true)

            signal:destroy()
        end)

        it("should have deferred property be false initially", function()
            local signal = Signal.new()

            expect(signal.deferred).to.equal(false)

            signal:destroy()
        end)

        it("should have queueing property be false initially", function()
            local signal = Signal.new()

            expect(signal.queueing).to.equal(false)

            signal:destroy()
        end)
    end)

    describe("Signal.is", function()
        it("should return true if object is a Signal", function()
            local signal = Signal.new()

            expect(signal.is(signal)).to.equal(true)

            signal:destroy()
        end)

        it("should return false if object is not a signal", function()
            local signal = Signal.new()

            expect(signal.is(empty)).to.equal(false)
            expect(signal.is(true)).to.equal(false)
            expect(signal.is(empty)).to.equal(false)
            expect(signal.is("string")).to.equal(false)

            signal:destroy()
        end)
    end)

    describe("Signal:enableQueueing", function()
        it("should set queueing property to true", function()
            local signal = Signal.new()
            
            signal:enableQueueing()
            expect(signal.queueing).to.equal(true)

            signal:destroy()
        end)
    end)

    describe("Signal:disableQueueing", function()
        it("should set queueing property to false", function()
            local signal = Signal.new()
            
            signal:enableQueueing()
            expect(signal.queueing).to.equal(true)

            signal:disableQueueing()
            expect(signal.queueing).to.equal(false)

            signal:destroy()
        end)
    end)

    describe("Signal:enableDeferred", function()
        it("should set deferred property to true", function()
            local signal = Signal.new()
            
            signal:enableDeferred()
            expect(signal.deferred).to.equal(true)

            signal:destroy()
        end)
    end)

    describe("Signal:disableDeferred", function()
        it("should set deferred property to false", function()
            local signal = Signal.new()
            
            signal:enableDeferred()
            expect(signal.deferred).to.equal(true)

            signal:disableDeferred()
            expect(signal.deferred).to.equal(false)

            signal:destroy()
        end)
    end)
    
    describe("Signal:fire", function()
        it("should queue passed args and fire the first connection with them if queueing", function()
            local signal = Signal.new()
            signal:enableQueueing()

            local done = false

            signal:fire(true)

            signal:connect(function(value)
                done = value
            end)

            expect(done).to.equal(true)

            signal:destroy()
        end)

        it("should not fire the first connection with queued args if the args are flushed first", function()
            local signal = Signal.new()
            signal:enableQueueing()

            local done = false

            signal:fire(true)
            signal:flush()

            signal:connect(function(value)
                done = value
            end)

            expect(done).to.equal(false)

            signal:fire(true)
            expect(done).to.equal(true)

            signal:destroy()
        end)

        it("should not queue passed args and fire the first connection with them if not queueing", function()
            local signal = Signal.new()
            local done = false

            signal:fire(true)

            signal:connect(function(value)
                done = value
            end)

            expect(done).to.equal(false)

            signal:destroy()
        end)

        it("should fire connected connections with the passed args", function()
            local signal = Signal.new()
            local count = 0

            signal:connect(function(inc)
                count += inc
            end)

            signal:connect(function(inc)
                count += inc * 2
            end)

            signal:fire(1)
            expect(count).to.equal(3)
            
            signal:destroy()
        end)

        it("should fire disconnected connections that were disconnected during :fire if not deferred", function()
            local signal = Signal.new()
            local done0, done1 = false, false

            local connection = signal:connect(function(bool)
                done0 = bool
            end)

            signal:connect(function(bool)
                done1 = bool
                connection:disconnect()

                -- This test and those similar to it work based on assumptions in the order of how handlers are called
                -- The order that handlers are called isn't behavior to rely on but I think it's important to have
                -- well defined behavior.
            end)

            signal:fire(true)

            expect(done0).to.equal(true)
            expect(done1).to.equal(true)

            signal:destroy()
        end)

        it("should not fire disconnected connections that were disconnected outside :fire if not deferred", function()
            local signal = Signal.new()
            local done0, done1 = false, false

            local connection = signal:connect(function(bool)
                done0 = bool
            end)

            signal:connect(function(bool)
                done1 = bool
            end)

            connection:disconnect()
            signal:fire(true)

            expect(done0).to.equal(false)
            expect(done1).to.equal(true)
            
            signal:destroy()
        end)

        it("should fire connections connected at the time of fire call with the passed args at the end of the frame if deferred", function()
            local signal = Signal.new()
            signal:enableDeferred()

            local done0, done1, done2 = false, false, false

            signal:connect(function(bool)
                done0 = bool
            end)

            signal:connect(function(bool)
                done1 = bool
            end)

            signal:fire(true)

            signal:connect(function(bool)
                done2 = bool
            end)

            -- Should be false since the fire call is deferred until the end of the frame

            expect(done0).to.equal(false)
            expect(done1).to.equal(false)
            expect(done2).to.equal(false)

            RunService.RenderStepped:Wait()

            expect(done0).to.equal(true)
            expect(done1).to.equal(true)
            expect(done2).to.equal(false)

            signal:destroy()
        end)

        it("should fire disconnected connections at the end of the frame that were disconnected from between the fire call to the end of the frame if deferred", function()
            local signal = Signal.new()
            signal:enableDeferred()

            local done0, done1 = false, false

            signal:connect(function(bool)
                done0 = bool
            end)

            signal:connect(function(bool)
                done1 = bool
            end)

            signal:fire(true)

            expect(done0).to.equal(false)
            expect(done1).to.equal(false)

            signal:disconnectAll()
            RunService.RenderStepped:Wait()

            expect(done0).to.equal(true)
            expect(done1).to.equal(true)

            signal:destroy()
        end)

        it("should not fire disconnected connections at the end of the frame that were disconnected outside the deferred fire call to the end of the frame if deferred", function()
            local signal = Signal.new()
            signal:enableDeferred()

            local done = false

            signal:connect(function(bool)
                done = bool
            end)
            
            signal:disconnectAll()
            signal:fire(true)

            expect(done).to.equal(false)

            RunService.RenderStepped:Wait()

            expect(done).to.equal(false)

            signal:destroy()
        end)

        it("should not fire connected connections that were connected after the fire call if deferred", function()
            local signal = Signal.new()
            signal:enableDeferred()

            local done = false

            signal:fire(true)

            signal:connect(function(bool)
                done = bool
            end)

            RunService.RenderStepped:Wait()
            expect(done).to.equal(false)

            signal:fire(true)

            RunService.RenderStepped:Wait()
            expect(done).to.equal(true)

            signal:destroy()
        end)
    end)
    
    describe("Signal:wait", function()
        it("should yield until signal is fired and return passed args from fire call", function()
            local signal = Signal.new()
            local result = false

            task.spawn(function()
                result = signal:wait()
            end)

            expect(result).to.equal(false)
            signal:fire(true)
            expect(result).to.equal(true)

            signal:destroy()
        end)
    end)
    
    describe("Signal:promise", function()
        it("should return a promise", function()
            local signal = Signal.new()
            local promise = signal:promise()

            expect(Promise.is(promise)).to.equal(true)

            signal:destroy()
        end)

        it("should return a promise that resolves with the outcome of :wait", function()
            local signal = Signal.new()
            local result = false

            signal:promise():andThen(function(value)
                result = value
            end)

            expect(result).to.equal(false)
            signal:fire(true)
            expect(result).to.equal(true)

            signal:destroy()
        end)
    end)
    
    describe("Signal:connect", function()
        it("should return a connection object that uses the passed handler", function()
            local signal = Signal.new()
            local connection = signal:connect(noop)
            
            expect(connection.is(connection)).to.equal(true)

            signal:destroy()
        end)

        it("should return a connection that is connected initially", function()
            local signal = Signal.new()
            local connection = signal:connect(noop)

            expect(connection.connected).to.equal(true)

            signal:destroy()
        end)

        it("should call an onActivated callback if it's set and it's the only connection", function()
            local signal = Signal.new()
            local value = 0

            signal:setActivatedCallback(function()
                value += 1
            end)

            expect(value).to.equal(0)
            
            signal:connect(noop):disconnect()
            expect(value).to.equal(1)
            
            signal:connect(noop)
            expect(value).to.equal(2)

            signal:connect(noop)
            expect(value).to.equal(2)

            signal:destroy()
        end)
    end)

    describe("Signal:once", function()
        it("should return a connection that will disconnect after being fired once", function()
            local signal = Signal.new()

            local connection = signal:once(noop)

            signal:fire()
            expect(connection.connected).to.equal(false)

            signal:destroy()
        end)

        it("should not call the handler if fired more than once", function()
            local signal = Signal.new()
            local value = 0

            local connection = signal:once(function(inc)
                value += inc
            end)

            signal:fire(2)
            expect(value).to.equal(2)
            expect(connection.connected).to.equal(false)
            
            signal:fire(1)
            expect(value).to.equal(2)

            signal:destroy()
        end)
    end)
    
    describe("Signal:disconnectAll", function()
        it("should disconnect all connected connections", function()
            local signal = Signal.new()
            local connection0 = signal:connect(noop)
            local connection1 = signal:connect(noop)

            expect(connection0.connected).to.equal(true)
            expect(connection1.connected).to.equal(true)

            signal:disconnectAll()

            expect(connection0.connected).to.equal(false)
            expect(connection1.connected).to.equal(false)

            signal:destroy()
        end)

        it("should call a onDeactivated callback if it's set", function()
            local signal = Signal.new()
            local value = 0

            signal:setDeactivatedCallback(function()
                value += 1
            end)

            signal:connect(noop)
            expect(value).to.equal(0)

            signal:disconnectAll()
            expect(value).to.equal(1)

            signal:destroy()
        end)
    end)

    describe("Signal:destroy", function()
        it("should disconnect all connected connections and set destroyed field to true", function()
            local signal = Signal.new()
            local connection0 = signal:connect(noop)
            local connection1 = signal:connect(noop)

            expect(connection0.connected).to.equal(true)
            expect(connection1.connected).to.equal(true)
            expect(signal.destroyed).to.equal(nil)
            
            signal:destroy()

            expect(connection0.connected).to.equal(false)
            expect(connection1.connected).to.equal(false)
            expect(signal.destroyed).to.equal(true)
        end)
    end)
end