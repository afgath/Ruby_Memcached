require 'socket'
require 'time'
require './item'
require './utils'

class Memcached
  attr_accessor :port
  attr_reader :hostname, :server, :highest_id, :cache, :mutex, :utils

  def initialize(port)
    @cache = {}
    @hostname = '127.0.0.1'
    @port = port
    @server = TCPServer.open(@hostname, port)
    @highest_id = 1
    @mutex = Mutex.new
    @utils = Utils.new
  end

  def purge_values
    Thread.new do
      interval = 600 # 10 minutes
      loop do
        @cache.delete_if {|key, value| (Time.new - value.time).to_i >= value.exptime.to_i}
        sleep(interval)
      end
    end
  end

  def delete(array_validate)
    if @cache[array_validate[1]].nil?
      Utils::NOT_FOUND_ERR
    else
      @cache.delete(array_validate[1])
      Utils::DELETED_MSG
    end
  end

  def add_item(key, item, value)
    @cache[key] = item
    @cache[key].value = value
    @cache[key].time = Time.new
    @cache[key].id = @highest_id
    @highest_id += 1
  end

  # Case save commands(set, add, replace)
  def save(array_validate, value, socket)
    if array_validate.count == 5 # If item hasn't set the NoReply attribute
      item = Item.new(array_validate[2], array_validate[3], array_validate[4], '', nil , nil, 0)
    elsif array_validate.count == 6 # If item has set the NoReply attribute
      item = Item.new(array_validate[2], array_validate[3], array_validate[4], array_validate[5], nil , nil, 0)
    end
    valid_value = @utils.validate_value(item.bytes, value)
    if value == ''
      value = " \n"
    end
    while valid_value.nil? do
      new_value = socket.gets
      if new_value.chomp != ''
        new_value = new_value.chomp
      end
      value += "\n" + new_value
      valid_value = @utils.validate_value(item.bytes, value)
    end
    if valid_value
      if (array_validate[0].upcase == Utils::ADD && @cache.any? && !@cache[array_validate[1]].nil?) ||
          (array_validate[0].upcase == Utils::REPLACE && @cache[array_validate[1]].nil?) # If command=add then key must not exist
        Utils::NOT_STORED_MSG
      else
        add_item(array_validate[1], item, value)
        Utils::STORED_MSG
      end
    else
      Utils::CHUNK_ERR
    end
  end

  def get(array_validate)
    item = @cache[array_validate[1]]
    if item
      item_value = (item.get_value.gsub! "\n\n", "\n")
      item_value ||= item.get_value
      # GETS
      value = 'VALUE ' + array_validate[1] + ' ' + item.to_s + ' ' + item.id.to_s + "\r\n" + item_value unless item.nil? || array_validate[0].upcase == Utils::GET
      # GET
      value = 'VALUE ' + array_validate[1] + ' ' + item.to_s + "\r\n" + item_value unless item.nil? || array_validate[0].upcase == Utils::GETS
      value += "\r\n" unless value.nil?
      value
    end
  end

  def concat(array_validate, value, socket)
    if @cache[array_validate[1]].nil?
      return Utils::NOT_STORED_MSG
    end
    valid_value = @utils.validate_value(array_validate[4], value)
    if value == ''
      value = " \n"
    end
    while valid_value.nil? do
      new_value = socket.gets
      if new_value.chomp != ''
        new_value = new_value.chomp
      end
      value += "\n" + new_value
      valid_value = @utils.validate_value(array_validate[4], value)
    end
    if valid_value
      @cache[array_validate[1]].value = @cache[array_validate[1]].value.to_s + value.to_s unless array_validate[0].upcase == Utils::PREPEND
      @cache[array_validate[1]].value = value.to_s + @cache[array_validate[1]].value.to_s unless array_validate[0].upcase == Utils::APPEND
      @cache[array_validate[1]].flags = array_validate[2]
      @cache[array_validate[1]].exptime = array_validate[3]
      @cache[array_validate[1]].bytes = (@cache[array_validate[1]].bytes.to_i + array_validate[4].to_i).to_s
      @cache[array_validate[1]].id = @highest_id
      @highest_id += 1
      Utils::STORED_MSG
    else
      Utils::CHUNK_ERR
    end
  end

  def start
    purge_values
    threads = loop do
      Thread.new(@server.accept) do |socket| # Multi-thread started so it can serve multiple clients
        request = nil
        @mutex.synchronize do
          request = socket.gets.chomp
        end
        loop do
          if request.nil? # Case: is not first command it receives the new interactions
            @mutex.synchronize do
              request = socket.gets
            end
            if request.nil?
              socket.close
              Thread.exit
            else
              request = request.chomp # To avoid chomp a nil
            end
          end
          array_validate = request.split(' ')
          headers_error = @utils.validate_headers(array_validate)
          if headers_error.nil? || headers_error == ''
            # If item is already expired, then is deleted before any process
            if !@cache[array_validate[1]].nil? && @cache[array_validate[1]].exptime.to_i.positive? && (Time.new - @cache[array_validate[1]].time).to_i >= @cache[array_validate[1]].exptime.to_i
              @cache.delete(array_validate[1])
            end
            @mutex.synchronize do
              case array_validate[0].upcase
              when Utils::QUIT
                socket.close
                Thread.exit
              when Utils::DELETE
                socket.write(delete(array_validate))
              when Utils::SET, Utils::ADD, Utils::REPLACE
                value = socket.gets.chomp
                socket.write(save(array_validate, value, socket))
              when Utils::GET, Utils::GETS
                socket.write(get(array_validate))
                socket.write(Utils::END_MSG)
              when Utils::APPEND, Utils::PREPEND
                value = socket.gets.chomp
                socket.write(concat(array_validate, value, socket))
              else
                socket.write(Utils::BASIC_ERR)
              end
            end
          else
            socket.write(headers_error)
          end
          request = nil
        end
      end
    end
    threads.each(&:join)
  end

end
memcached = Memcached.new(1997)
memcached.start