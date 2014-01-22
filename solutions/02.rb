class ArrayMethods
  def self.arr_contains(array,subarray)
    array.all? { |e| subarray.include?(e) }
  end
end

class Criteria
  attr_reader :value_check

  def initialize(checker)
    @value_check = checker
  end

  def self.status(symbol)
    Criteria.new ->(record){record["status"] == symbol}
  end

  def self.priority(symbol)
    Criteria.new ->(record){record["priority"] == symbol}
  end

  def self.tags(tags)
    Criteria.new ->(record){
      ArrayMethods.arr_contains tags,record["tags"]
    }
  end

  def &(other)
    Criteria.new ->(record){@value_check[record] and other.value_check[record]}
  end

  def |(other)
    Criteria.new ->(record){@value_check[record] or other.value_check[record]}
  end

  def !
    Criteria.new ->(record){not @value_check[record]}
  end
end

class BaseLineResolver
  def resolve_line(text_values)
    hash , values = {} , line_values(text_values.split('|'))
    keys.each_index { |i|
      hash[keys[i]] = values[i]
    }
    hash
  end
end

class TodoLineResolver < BaseLineResolver
  def resolve_array_value(value)
    if value == nil then return [] end
    value.split(',').map { |arr_value|
      arr_value.strip.freeze
    }
  end

  def line_value_array(vals)
    [vals[0].downcase.to_sym,
    vals[1],
    vals[2].downcase.to_sym,
    resolve_array_value(vals[3])]
  end

  def line_values(vals)
    line_value_array vals.map {|value|
      value.strip
    }
  end

  def keys
    ["status","description","priority","tags"]
  end
end

class DataSet
  include Enumerable
  attr_reader :data

  def initialize(data)
    @data = data
  end

  def each &block
    @data.each do |data|
      block_given? block.call data: data
    end
  end
end

class TodoList < DataSet
  @resolver = TodoLineResolver.new
  def self.parse(list)
    TodoList.new list.lines.map { |line|
      @resolver.resolve_line line
    }
  end

  def filter(criteria)
    @data.select { |record|
      criteria.value_check.call(record)
    }
  end

  def tasks_todo
    (filter Criteria.status(:todo)).length
  end

  def tasks_in_progress
    (filter Criteria.status(:current)).length
  end

  def tasks_completed
    (filter Criteria.status(:done)).length
  end

  def completed?
    (tasks_todo == 0) and (tasks_in_progress == 0)
  end
end
