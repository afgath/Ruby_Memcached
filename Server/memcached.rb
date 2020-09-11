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
  def start
    threads = loop do
      Thread.new(@server.accept) do |socket| # Multithread started so it can serve multiple clients
        @mutex.synchronize do
          request = socket.gets.chomp
          loop do
            if request.nil? # Case: is not first command it receives the new interactions
              request = socket.gets
              request = request.chomp unless request.nil? # To avoid chomp a nil
            end
            array_validate = request.split(' ')
            headers_error = @utils.validate_headers(array_validate)
            if headers_error.nil? || headers_error == ''
              # If item is already expired, then is deleted before any process
              if !@cache[array_validate[1]].nil? && @cache[array_validate[1]].exptime.to_i.positive? && (Time.new - @cache[array_validate[1]].time).to_i >= @cache[array_validate[1]].exptime.to_i
                @cache.delete(array_validate[1])
              end
              case array_validate[0].upcase
              when @utils.DELETE
                delete(array_validate)
              else
                socket.write(@utils.BASIC_ERR)
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

  def self.delete(array_validate)
    if @cache[array_validate[1]].nil?
      @utils.NOT_FOUND_ERR
    else
      @cache.delete(array_validate[1])
      @utils.DELETED_MSG
    end
  end

end
memcached = Memcached.new(1997)
memcached.start