local function ends_in_3(num)
  return num % 10 == 3
end

local function is_prime(num)
  for i = 2, math.sqrt(num) do
    if num % i == 0 then
      return false
    end
  end
  return true
end

local function primes_ends_in_3(n)
  local primes = {}
  local count = 0
  for i = 3, math.maxinteger do
    if count >= n then break end
    if ends_in_3(i) and is_prime(i) then
      count = count + 1
      primes[count] = i
    end
  end
  return primes
end

return {
  ends_in_3 = ends_in_3,
  is_prime = is_prime,
  primes_ends_in_3 = primes_ends_in_3
}
