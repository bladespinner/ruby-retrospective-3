class Integer
  def prime?
    return false if self <= 1
    (2 ... Math.sqrt(self)).all? do |divider|
     self % divider != 0
    end
  end

  def absolute
    self < 0 ? -self : self
  end

  def prime_factors
    prime_factor = (2..self).find{|divisor| self % divisor == 0}
    prime_factor ? [prime_factor] + (self / prime_factor).prime_factors : []
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
    hash = Hash.new 0
    self.each{ |element| hash[element] += 1}
    hash
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

p [1,2,1,1,1,1,11,1,13,4,2,1,3,5,2,5].frequencies