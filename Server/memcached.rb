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
      value = "\r\n"
    end
    while valid_value.nil? do
      new_value = socket.gets
      if new_value.chomp != ''
        new_value = new_value.chomp
      end
      value += new_value
      valid_value = @utils.validate_value(item.bytes, value)
    end
    if valid_value
      if (array_validate[0].upcase == Utils::ADD && @cache.any? && !@cache[array_validate[1]].nil?) ||
          (array_validate[0].upcase == Utils::REPLACE && @cache[array_validate[1]].nil?) # If command=add then key must not exist
        NOT_STORED_MSG
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
    # GETS
    value = 'VALUE ' + array_validate[1] + ' ' + item.to_s + ' ' + item.id.to_s + "\r\n" + item.get_value unless item.nil? || array_validate[0].upcase == Utils::GET
    # GET
    value = 'VALUE ' + array_validate[1] + ' ' + item.to_s + "\r\n" + item.get_value unless item.nil? || array_validate[0].upcase == Utils::GETS
    value += "\r\n" unless value.nil?
    value
  end

  def start
    threads = loop do
      Thread.new(@server.accept) do |socket| # Multithread started so it can serve multiple clients
        @mutex.synchronize do
          request = socket.gets.chomp
          loop do
            if request.nil? # Case: is not first command it receives the new interactions
              request = socket.gets
              if request.nil?
                socket.close
                break
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
              case array_validate[0].upcase
              when Utils::DELETE
                socket.write(delete(array_validate))
              when Utils::SET, Utils::ADD, Utils::REPLACE
                value = socket.gets.chomp
                socket.write(save(array_validate, value, socket))
              when Utils::GET, Utils::GETS
                socket.write(get(array_validate))
                socket.write(Utils::END_MSG)
              else
                socket.write(Utils::BASIC_ERR)
              end
            else
              socket.write(headers_error)
            end
            request = nil
          end
        end
      end
    end
    threads.each(&:join)
  end

end
memcached = Memcached.new(1997)
memcached.start