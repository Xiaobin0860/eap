require 'busted.runner'()

insulate("Seven More Languages in Seven Weeks 1 #7w7 #day1", function()
    local day1 = require("七周七.day1")
    it("day1 tests", function()
        assert.is_true(day1.ends_in_3(3))
        assert.is_true(day1.ends_in_3(13))
        assert.is_false(day1.ends_in_3(31))
        assert.is_true(day1.is_prime(2))
        assert.is_true(day1.is_prime(3))
        assert.is_true(day1.is_prime(65537))
        assert.is_false(day1.is_prime(4294967297))
        assert.are_same({3}, day1.primes_ends_in_3(1))
        assert.are_same({3, 13}, day1.primes_ends_in_3(2))
        assert.are_same({3, 13, 23}, day1.primes_ends_in_3(3))
        local sum = 0
        local f = function(i)
            sum = sum + i
        end
        day1.for_loop(1, 10, f)
        assert.are_equal(55, sum)
        sum = 0
        day1.for_loop1(1, 10, f)
        assert.are_equal(55, sum)
        local add = function(a, b)
            return a + b
        end
        assert.are_equal(15, day1.reduce(5, 0, add))
        assert.are_equal(20, day1.reduce(5, 5, add))
        assert.are_equal(1, day1.factorial(1))
        assert.are_equal(1, day1.factorial1(1))
        assert.are_equal(1, day1.factorial2(1))
        assert.are_equal(720, day1.factorial(6))
        assert.are_equal(720, day1.factorial1(6))
        assert.are_equal(720, day1.factorial2(6))
    end)
end)

insulate("Seven More Languages in Seven Weeks 2 #7w7 #day2", function()
    local day2 = require("七周七.day2")
    it("meta", function()
        local a = {1, 2, 3}
        local b = {"a", "b", "c"}
        assert.are_same({1, 2, 3, "a", "b", "c"}, day2.concatenate(a, b))
        local treasure = day2.treasure
        treasure.gold = 100
        assert.are_equal(100, treasure.gold)
        assert.has_error(function()
            treasure.gold = 200
        end, "key already exists: gold")
        assert.has_error(function()
            print(treasure.silver)
        end, "key not found: silver")
        treasure.gold = nil
        assert.has_error(function()
            print(treasure.gold)
        end, "key not found: gold")
        treasure.gold = 200
        assert.are_equal(200, treasure.gold)
        local mt = {
            __add = day2.concatenate
        }
        setmetatable(a, mt)
        setmetatable(b, mt)
        assert.are_same({1, 2, 3, "a", "b", "c"}, a + b)
    end)

    it("Queue", function()
        local Queue = day2.Queue
        local q = Queue.new()
        assert.are_equal(nil, q:remove())
        q:add("1")
        q:add(2)
        assert.are_equal("1", q:remove())
        assert.are_equal(2, q:remove())
        assert.are_equal(nil, q:remove())
        assert.are_equal(nil, q:remove())
    end)

    it("retry", function()
        local retry = day2.retry
        local ct, result = retry(5, function()
            if math.random() > 0.2 then
                coroutine.yield(false)
            end
            print("success")
            return true, {1, "2"}
        end)
        print("retry count: " .. ct)
        if ct > 5 then
            assert.are_equal(6, ct)
            assert.are_equal(nil, result)
        else
            assert.are_same({1, "2"}, result)
        end
    end)

    local scheduler = require("七周七.scheduler")
    it("schedule", function()
        local function punch()
            for i = 1, 5 do
                print("punch " .. i)
                scheduler.wait(1.0)
            end
        end
        local function block()
            for i = 1, 3 do
                print("block " .. i)
                scheduler.wait(2.0)
            end
        end
        scheduler.schedule(0.0, coroutine.create(punch))
        scheduler.schedule(0.0, coroutine.create(block))
        scheduler.run()
    end)
end)
