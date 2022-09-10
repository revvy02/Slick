local TrueSignal = require(script.Parent.Parent.TrueSignal)
local Store = require(script.Parent.Store)

return function()
    describe("Store.new", function()
        it("should create a new store object", function()
            local store = Store.new()

            expect(store).to.be.a("table")
            expect(getmetatable(store)).to.equal(Store)
        end)

        it("should set the initial state if passed", function()
            local initial = {a = 1, b = 2, c = 3}
            local store = Store.new(initial)

            expect(store:getState()).to.equal(initial)
        end)

        it("should have an empty table as the state if no initial is passed", function()
            local store = Store.new()

            expect(next(store:getState())).to.equal(nil)
        end)

        it("should use the reducers passed instead of the standard reducers", function()
            local store = Store.new({
                key = 0
            }, {
                increment = function(old, amount)
                    return old + amount
                end,
            })

            expect(function()
                store:dispatch("setValue", "key", 2)
            end).to.throw()

            expect(function()
                store:dispatch("increment", "key", 3)
            end).to.never.throw()

            expect(store:getValue("key")).to.equal(3)
        end)

        it("should use the standard reducers if none are passed", function()
            local store = Store.new({
                key = 0
            })

            expect(function()
                store:dispatch("setValue", "key", 2)
            end).to.never.throw()

            expect(store:getValue("key")).to.equal(2)
        end)
    end)

    describe("Store:setDepth", function()
        it("should set the depth of the store", function()
            local store = Store.new({a = 1, b = 2, c = 3})
            
            store:setDepth(3)
            expect(store:getDepth()).to.equal(3)
        end)
        
        it("should trim any excess history off depending on depth", function()
            local store = Store.new({a = 1, b = 2, c = 3})

            store:setDepth(3)

            store:dispatch("setValue", "a", 2)
            store:dispatch("setValue", "a", 3)
            store:dispatch("setValue", "a", 4)

            expect(store:getHistory()[3].a).to.equal(1)

            store:dispatch("setValue", "a", 5)

            expect(#store:getHistory()).to.equal(3)
            expect(store:getHistory()[3].a).to.equal(2)

            store:setDepth(1)
            expect(#store:getHistory()).to.equal(1)
            expect(store:getHistory()[1].a).to.equal(4)
        end)
    end)

    describe("Store:getDepth", function()
        it("should return the depth of the store", function()
            local store = Store.new()

            store:setDepth(10)

            expect(store:getDepth()).to.equal(10)
        end)
    end)
    
    describe("Store:getHistory", function()
        it("should return the history depending on the depth of the store", function()
            local store = Store.new()

            store:setDepth(2)

            store:dispatch("setValue", "a", 1)
            store:dispatch("setValue", "a", 2)
            store:dispatch("setValue", "a", 3)
            store:dispatch("setValue", "a", 4)

            expect(#store:getHistory()).to.equal(2)
            expect(store:getHistory()[1].a).to.equal(3)
            expect(store:getHistory()[2].a).to.equal(2)
        end)

        it("should return a frozen table", function()
            local store = Store.new()

            store:setDepth(2)

            store:dispatch("setValue", "a", 1)
            store:dispatch("setValue", "a", 2)
            store:dispatch("setValue", "a", 3)
            store:dispatch("setValue", "a", 4)

            expect(table.isfrozen(store:getHistory())).to.equal(true)
        end)
    end)

    describe("Store:rawsetValue", function()
        it("should set the key value without firing signals", function()
            local store = Store.new()
            local done = false

            store:getChangedSignal("a"):connect(function()
                done = true
            end) 

            store:getReducedSignal("setValue", "a"):connect(function()
                done = true
            end)

            store.changed:connect(function()
                done = true
            end)

            store:rawsetValue("a", 1)

            expect(store:getValue("a")).to.equal(1)
            expect(done).to.equal(false)
        end)
    end)

    describe("Store:rawsetState", function()
        it("should set the store state without firing signals", function()
            local store = Store.new()
            local done = false

            store.changed:connect(function()
                done = true
            end)

            store.reduced:connect(function()
                done = true
            end)

            store:rawsetState({
                a = 0,
                b = 1,
            })

            expect(store:getValue("a")).to.equal(0)
            expect(store:getValue("b")).to.equal(1)
            expect(done).to.equal(false)
        end)
    end)

    describe("Store:setReducers", function()
        it("should use the passed reducers for the store", function()
            local store = Store.new({
                value = 0,
            })

            store:setReducers({
                increment = function(old, amount)
                    return old + amount
                end,
            })

            expect(function()
                store:dispatch("increment", "value", 10)
            end).to.never.throw()

            expect(function()
                store:dispatch("setValue", "value", 20)
            end).to.throw()
        end)
    end)

    describe("Store:getValue", function()
        it("should return the value of the key in the store", function()
            local store = Store.new({
                value = 0,
            })

            expect(store:getValue("value")).to.equal(0)
            expect(store:getValue("other")).to.never.be.ok()
        end)

        it("should return a frozen table if the value is a table", function()
            local store = Store.new({
                value = {
                    a = 1,
                }
            })

            expect(table.isfrozen(store:getValue("value"))).to.equal(true)
        end)
    end)

    describe("Store:getReducedSignal", function()
        it("should get the reduced signal for the passed key and reducer", function()
            local store = Store.new()

            local signal = store:getReducedSignal("setValue", "a")

            expect(signal).to.be.a("table")
            expect(getmetatable(signal)).to.equal(TrueSignal)
        end)
    end)


    describe("Store:getChangedSignal", function()
        it("should return a changed signal for the passed key", function()
            local store = Store.new()

            local signal = store:getChangedSignal("a")

            expect(signal).to.be.a("table")
            expect(getmetatable(signal)).to.equal(TrueSignal)
        end)
    end)

    describe("Store:dispatch", function()
        it("should change the value correctly", function()
            local store = Store.new()

            store:dispatch("setValue", "a", 1)
            expect(store:getValue("a")).to.equal(1)
        end)

        it("should throw if reducer doesn't exist", function()
            local store = Store.new()

            expect(function()
                store:dispatch("set", "a", 1) -- reducer is setValue, not set, so this should error
            end).to.throw()
        end)

        it("should fire the public changed signal", function()
            local store = Store.new({a = 1})
            local key, new, old

            store.changed:connect(function(...)
                key, new, old = ...
            end)

            store:dispatch("setValue", "a", 2)

            expect(store:getValue("a")).to.equal(2)
            expect(key).to.equal("a")
            expect(new.a).to.equal(2)
            expect(old.a).to.equal(1)
        end)

        it("should fire the public reduced signal", function()
            local store = Store.new({a = 1})
            local reducer, key, value

            store.reduced:connect(function(...)
                reducer, key, value = ...
            end)

            store:dispatch("setValue", "a", 2)

            expect(store:getValue("a")).to.equal(2)
            expect(key).to.equal("a")
            expect(reducer).to.equal("setValue")
            expect(value).to.equal(2)
        end)

        it("should fire the appropriate key changed signal", function()
            local store = Store.new({a = 1})
            local new, old

            store:getChangedSignal("a"):connect(function(...)
                new, old = ...
            end)

            store:dispatch("setValue", "a", 2)

            expect(new).to.equal(2)
            expect(old).to.equal(1)
        end)

        it("should fire the appropriate key reduced signal", function()
            local store = Store.new({a = {}})
            local index, value

            store:getReducedSignal("setIndex", "a"):connect(function(...)
                index, value = ...
            end)

            store:dispatch("setIndex", "a", "a", 1)

            expect(index).to.equal("a")
            expect(value).to.equal(1)
            expect(store:getValue("a").a).to.equal(1)
        end)

    end)

   
    


    describe("Store:destroy", function()
        it("should disconnect any connections", function()
            local store = Store.new()

            local connection0 = store:getChangedSignal("a"):connect(function() end)
            local connection1 = store:getReducedSignal("setValue", "a"):connect(function() end)

            store:destroy()

            expect(connection0.connected).to.equal(false)
            expect(connection1.connected).to.equal(false)
        end)
    end)
end