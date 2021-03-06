module Enumerable
  def min_by
    pairs = map{|x| [yield(x), x] }
    min_pair = pairs.min{|a, b| a.first <=> b.first }
    return min_pair.last
  end

  def sum
    inject(0) {|a, b| a + b } rescue nil
  end

  @@permutations_cache = {}

  def permutations
    return @@permutations_cache[self].dup if @@permutations_cache[self]
    return [[]] if empty?
    others = rest.permutations
    return (@@permutations_cache[self.dup] = (others.map{|o| [first] + o} + others).uniq).dup
  end

  def rest
    return [] if empty?
    self[1..-1]
  end
end

class Prices
  def initialize(*data)
    @data = data
  end

  def get
    @data[rand(@data.size)]
  end

  def each(count)
    count.times{ yield get }
  end
end

class ChangeMaker
  def initialize(*coins)
    raise "ChangeMaker must have a coin of denomination 1" unless coins.include?(1)
    @coins = coins.sort
    @cache = {}
  end

  def change(amount)
    return @cache[amount] if @cache[amount]
    return [] if amount == 0

    possible = @coins.find_all{|coin| coin <= amount }
    best = possible.min_by{|coin| change(amount - coin).size }

    return @cache[amount] = [best, *change(amount - best)].sort
  end
end

class Customer
  def self.us(*coins)
    self.new([1, 5, 10, 25], *coins)
  end

  attr_reader :denoms, :coins

  def initialize(denoms, *coins)
    @coins  = coins.sort
    @denoms = denoms.sort

    coins.each{|denom| check_denom(denom) }

    @cm = ChangeMaker.new(*@denoms)
    check_optimal_start
  end

  def check_denom(denom)
    raise "Bad denomination #{denom}" unless denoms.include?(denom)
  end

  def check_optimal_start
    optimal = @cm.change(amount)
    if coins.size != optimal.size
      raise "Bad starting state #{coins.inspect} should be #{optimal.inspect}" 
    end
  end

  def amount
    coins.sum
  end

  def number
    coins.size
  end

  def ==(other)
    return false unless other.kind_of?(Customer)
    return false unless coins == other.coins
    return false unless denoms == other.denoms
    return true
  end

  def to_s
    dollars = sprintf("$%.2f", amount.to_f/100)
    return "#{dollars} (#{coins.join(', ')})"
  end

  def take!(coin)
    coins.push coin
    coins.sort!
    return self
  end

  def give!(coin)
    # Be careful not to call delete() because it removes all instances of an
    # object, and we support having more than one of each coin. Use delete_at
    # instead.
    raise "Don't have #{coin} coin to give" unless coins.include?(coin)
    coins.delete_at(coins.index(coin))
    return self
  end

  def pay!(bill)
    give = coins.permutations.min_by do |perm|
      amount = (perm.sum - bill) % 100
      change = @cm.change(amount)
      number - perm.size + change.size
    end

    amount = (give.sum - bill) % 100
    get = @cm.change(amount)

    give.each {|d| give!(d) }
    get.each  {|d| take!(d) }
    return self
  end
end

class ChangeSimulator
  def initialize(prices, *denoms)
    @prices   = prices
    @customer = Customer.new(denoms)
  end

  def run(length)
    sum = 0
    @prices.each(length) do |bill|
      @customer.pay!(bill)
      sum += @customer.number
    end
    return sum.to_f/length
  end
end

price_list = IO.readlines("prices.txt").map{|price| price.to_i }
prices = Prices.new(*price_list)

possibilities = []
us_denoms = [5, 10, 25]
us_denoms.size.times do |i|
  (2..99).each do |replacement|
    denoms    = us_denoms.dup
    denoms[i] = replacement

    possibilities << [1, *denoms]
  end
end

winner = possibilities.min_by do |denoms|
  sim = ChangeSimulator.new(prices, *denoms)
  sim.run(1000)
end

puts "The winner is: #{winner.sort.inspect}"
