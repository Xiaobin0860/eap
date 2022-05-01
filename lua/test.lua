require 'busted.runner' ()

insulate("Seven More Languages in Seven Weeks #7w7", function()
    local day1 = require("七周七.day1")
    it("day1 tests", function()
        assert.is_true(day1.ends_in_3(3))
        assert.is_true(day1.ends_in_3(13))
        assert.is_false(day1.ends_in_3(31))
        assert.is_true(day1.is_prime(2))
        assert.is_true(day1.is_prime(3))
        assert.is_true(day1.is_prime(65537))
        assert.is_false(day1.is_prime(4294967297))
        assert.are_same({ 3 }, day1.primes_ends_in_3(1))
        assert.are_same({ 3, 13 }, day1.primes_ends_in_3(2))
        assert.are_same({ 3, 13, 23 }, day1.primes_ends_in_3(3))
        local sum = 0
        local f = function(i) sum = sum + i end
        day1.for_loop(1, 10, f)
        assert.are_equal(55, sum)
        sum = 0
        day1.for_loop1(1, 10, f)
        assert.are_equal(55, sum)

        local add = function(a, b) return a + b end
        assert.are_equal(15, day1.reduce(5, 0, add))
        assert.are_equal(20, day1.reduce(5, 5, add))
    end)
end)
