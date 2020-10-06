require 'socket'
require 'time'
require_relative './item'
require_relative './utils'
require_relative './memcached'

class Server
  attr_accessor :port
  attr_reader :hostname, :server, :mutex, :utils, :threads

  def initialize(port)
    @hostname = '127.0.0.1'
    @port = port
    @server = TCPServer.open(@hostname, port)
    @mutex = Mutex.new
    @utils = Utils.new
    @memcache = Memcached.new
    @threads = [] # Threads opened to do operations
  end

  # Method used to start the server
  def start
    @memcache.purge_values unless @memcache.deletion_process
    @threads = loop do
      Thread.new(@server.accept) do |socket| # Multi-thread started so it can serve multiple clients
        request = nil
        loop do
          if request.nil?
            request = socket.gets
            if request.nil?
              socket.close
              Thread.exit
            else
              request = request.chomp # To avoid chomp a nil
              puts request
            end
          end
          array_validate = request.split(' ')
          headers_error = @utils.validate_headers(array_validate)
          if headers_error.nil? || headers_error == ''
            # If item is already expired, then is deleted before any process
            if !@memcache.cache[array_validate[1]].nil? && @memcache.cache[array_validate[1]].exptime.to_i.positive? &&
               (Time.new - @memcache.cache[array_validate[1]].time).to_i >= @memcache.cache[array_validate[1]].exptime.to_i
              @mutex.synchronize do # Synchronization of operations for mutual-exclusion and visibility
                @memcache.delete(array_validate[1])
              end
            end
            case array_validate[0].upcase
            when Utils::QUIT
              socket.close
              Thread.exit
            when Utils::DELETE
              @mutex.synchronize do # Synchronization of operations for mutual-exclusion and visibility
                socket.write(@memcache.delete(array_validate))
              end
            when Utils::SET, Utils::ADD, Utils::REPLACE, Utils::APPEND, Utils::PREPEND, Utils::CAS
              full_value = ''
              correct = nil
              first = true
              loop do
                value = socket.gets
                if first
                  full_value = value
                  first = false
                else
                  full_value += "\n" + value
                end
                correct = @utils.validate_value(array_validate[4],full_value)
                break unless correct.nil?
              end
              @mutex.synchronize do # Synchronization of operations for mutual-exclusion and visibility
                # Separated method depending on
                if correct && (array_validate[0].upcase == Utils::APPEND || array_validate[0].upcase == Utils::PREPEND)
                  socket.write(@memcache.concat(array_validate, full_value))
                elsif correct && array_validate[0].upcase == Utils::CAS
                  socket.write(@memcache.cas(array_validate, full_value))
                elsif correct
                  socket.write(@memcache.save(array_validate, full_value))
                else
                  socket.write(Utils::CHUNK_ERR)
                end
              end
            when Utils::GET, Utils::GETS
              socket.write(@memcache.get(array_validate))
              socket.write(Utils::END_MSG)
            when Utils::INCR, Utils::DECR
              @mutex.synchronize do # Synchronization of operations for mutual-exclusion and visibility
                socket.write(@memcache.incr_decr(array_validate))
              end 
            when Utils::FLUSH_ALL
              @mutex.synchronize do # Synchronization of operations for mutual-exclusion and visibility
                socket.write(@memcache.flush_all(array_validate))
              end
            else
              socket.write(Utils::BASIC_ERR)
            end
          else
            socket.write(headers_error)
          end
          request = nil
          @threads.each(&:join)
        end
      end
    end
  end
end

serv = Server.new(11211)
serv.start
