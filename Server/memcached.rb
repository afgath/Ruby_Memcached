require 'socket'
require 'time'
require_relative './item'
require_relative './utils'

class Memcached
  attr_accessor :cache, :highest_id, :timer
  attr_reader :utils, :deletion_process

  def initialize
    @cache = {}
    @highest_id = 1
    @utils = Utils.new
    @timer = nil # Thread that contains the flush_all if is timed
    @deletion_process = false
  end

  # Method to purge expired items from cache every 10 minutes
  def purge_values
    Thread.new do
      interval = 600 # 10 minutes
      loop do
        @cache.delete_if { |key, value| (Time.new - value.time).to_i >= value.exptime.to_i }
        sleep(interval)
      end
    end
    @deletion_process = true
  end

  # Method to delete specific item by key
  def delete(array_validate)
    if @cache[array_validate[1]].nil?
      Utils::NOT_FOUND_ERR
    else
      @cache.delete(array_validate[1])
      Utils::DELETED_MSG
    end
  end

  # Method to add a value to cache whenever
  # a storage command is used
  def add_item(key, item, value)
    @cache[key] = item
    @cache[key].value = value
    @cache[key].time = Time.new
    @cache[key].id = @highest_id
    @highest_id += 1
  end

  # Method for save commands(SET, ADD, REPLACE)
  # Specific cache validations for the operations
  def save(array_validate, value)
    if array_validate.count == 5 # If item hasn't set the NoReply attribute
      item = Item.new(array_validate[2], array_validate[3], array_validate[4], '', nil, nil, 0)
    elsif array_validate.count == 6 # If item has set the NoReply attribute
      item = Item.new(array_validate[2], array_validate[3], array_validate[4], array_validate[5], nil, nil, 0)
    end
    if (array_validate[0].upcase == Utils::ADD && @cache.any? && !@cache[array_validate[1]].nil?) ||
        (array_validate[0].upcase == Utils::REPLACE && @cache[array_validate[1]].nil?) # If command=add then key must not exist
      Utils::NOT_STORED_MSG
    else
      add_item(array_validate[1], item, value)
      Utils::STORED_MSG
    end
  end

  # Method for APPEND or PREPEND operations
  # Validates instance before concatenate the value
  # before or after the previous value
  def concat(array_validate, value)
    if @cache[array_validate[1]].nil?
      Utils::NOT_STORED_MSG
    else
      key = array_validate[1]
      item = @cache[array_validate[1]]
      local_value = @cache[array_validate[1]].value.to_s + value.to_s unless array_validate[0].upcase == Utils::PREPEND
      local_value = value.to_s + @cache[array_validate[1]].value.to_s unless array_validate[0].upcase == Utils::APPEND
      item.flags = array_validate[2]
      item.exptime = array_validate[3]
      item.bytes = (@cache[array_validate[1]].bytes.to_i + array_validate[4].to_i).to_s
      item.noreply = array_validate[5] unless array_validate[5].nil?
      add_item(key, item, local_value)
      Utils::STORED_MSG
    end
  end

  # Method to modify a value that hasn't been previously modified
  def cas(array_validate, value)
    if @cache[array_validate[1]].nil?
      Utils::NOT_FOUND_ERR
    elsif @cache[array_validate[1]].id.to_i != array_validate[5].to_i
      Utils::EXISTS_ERR
    else
      key = array_validate[1]
      item = @cache[array_validate[1]]
      item.flags = array_validate[2]
      item.exptime = array_validate[3]
      item.bytes = array_validate[4]
      item.noreply = array_validate[6]
      add_item(key, item, value)
      Utils::STORED_MSG
    end
  end

  # Method for increment or decrement a numeric value
  def incr_decr(array_validate)
    if !@cache[array_validate[1]].nil? && !@cache[array_validate[1]].value.to_i.nil? &&
       @cache[array_validate[1]].value.to_i.positive? && !array_validate[2].to_i.nil? && array_validate[2].to_i.positive?
      item = @cache[array_validate[1]]
      value = (item.value.to_i + array_validate[2].to_i).to_s unless array_validate[0].upcase == 'DECR'
      value = (item.value.to_i - array_validate[2].to_i).to_s unless array_validate[0].upcase == 'INCR'
      value = '0' unless value.to_i.positive?
      add_item(array_validate[1], item, value)
      value + "\r\n"
    elsif !@cache[array_validate[1]].nil? && (@cache[array_validate[1]].value.to_i.nil? ||
        !@cache[array_validate[1]].value.to_i.positive?)
      Utils::NUMERIC_VAL_ERR
    elsif !@cache[array_validate[1]].nil? && (array_validate[2].to_i.nil? || !array_validate[2].to_i.positive?)
      Utils::NUMERIC_DELTA_ERR
    else
      Utils::NOT_FOUND_ERR
    end
  end

  # Method when GET or GETS commands are used
  # Returns data fetched from cache by key
  def get(array_validate)
    item = @cache[array_validate[1]]
    if item
      item_value = (item.get_value.gsub! "\n\n", "\n")
      item_value ||= item.get_value
      # GETS
      value = 'VALUE ' + array_validate[1] + ' ' + item.to_s + ' ' + item.id.to_s + "\r\n" + item_value unless item.nil?|| array_validate[0].upcase == Utils::GET
      # GET
      value = 'VALUE ' + array_validate[1] + ' ' + item.to_s + "\r\n" + item_value unless item.nil? || array_validate[0].upcase == Utils::GETS
      value
    end
  end

  def flush_all(array_validate)
    Thread.kill(@timer) unless @timer.nil? #Kills previous thread to replace the timer
    if array_validate[1].nil? || array_validate[1].to_i.nil?
      @cache = {}
      @highest_id = 1
    else # Case flush_all command has a timer set
      @timer = Thread.new { sleep array_validate[1].to_i; ; @cache = {}; @highest_id = 1 }
    end
    Utils::OK_MSG
  end
end
