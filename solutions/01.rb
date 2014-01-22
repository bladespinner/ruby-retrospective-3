class Integer
  def prime?
    return false if self <= 1
    (2 ... Math.sqrt(self)).all? do |divider|
     self % divider != 0
    end
  end

  def next_prime
    prime = self + 1
    while not prime.prime? do prime = prime + 1 end
    return prime
  end

  def absolute
    self < 0 ? -self : self
  end

  def prime_factors
    prime , current , result = 2 , self , []
    while (current > 1) or (current < -1) do
      if current % prime == 0 then
        current=current/result.push(prime)[-1] else prime = prime.next_prime
      end
    end
    return result
  end

  def harmonic
    return 0 if self <= 0
    1.to_r/self + (self-1).harmonic
  end

  def digits
    self.absolute.to_s.split('').map { |digit| digit.to_i }
  end
end

class Array
  def frequencies
    hash = {}
    self.map{ |element| if hash[element] == nil
      then
        hash[element] = 1
      else
        hash[element] = hash[element] + 1
      end}
    return hash
  end
  def average
    sum = 0
    self.map{ |number| sum=sum + number}
    sum.to_f / self.length
  end
  def drop_every step
    count , result = 1 , []
    self.map{ |element| if not (count == step) then
      count = count + 1
      result.push(element)
    else count = 1 end }
    return result
  end
  def combine_with(other)
    if self == [] then return other end
    if other == [] then return self end
    [self[0]] + other.combine_with(self.drop(1))
  end
end

p 24.prime?