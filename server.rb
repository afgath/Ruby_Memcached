require 'socket'
require 'time'
require './item'

cache = {}
hostname = 'localhost'
port = 1997
server = TCPServer.open(hostname, port)

loop do
  Thread.start(server.accept) do |socket| # Multithread started so it can serve multiple clients
    request = socket.gets.chomp
    request = request[21, request.length]
    puts request
    loop do
      if request.nil? # Case: is not first command it receives the new interactions
        request = socket.gets.chomp
      end
      puts request[4, request.length]
      if request[0, 7].upcase == "REPLACE" || request[0, 3].upcase == "SET" || request[0, 3].upcase == "ADD"
        valid = true # Value that indicates If item is valid
        apply = true # value that indicates If the operation applies
        if request[4, request.length].nil?
          socket.write("ERROR\r\n")
          valid = false
        end
        if request[0, 7].upcase == "REPLACE"
          array_values = request[8, request.length].split(" ")
        else
          array_values = request[4, request.length].split(" ")
        end
        if array_values[2].to_i.negative?
          socket.write("ERROR\r\n")
          valid = false
        end
        if request[0, 3].upcase == "ADD" && cache.any? # If command=add then key must not exist
          apply = false unless cache[array_values[0]].nil?
        end
        if request[0, 7].upcase == "REPLACE" && cache[array_values[0]].nil? # If command=replace then key must exist
          apply = false
        end
        if array_values.count < 4 || array_values.count > 5
          socket.write("ERROR\r\n")
        else
          if valid
            if array_values.count == 4 # If item hasn't setted the NoReply attribute
              item = Item.new(array_values[1], array_values[2], array_values[3], '', Time.new, nil)
            elsif array_values.count == 5 # If item has setted the NoReply attribute
              item = Item.new(array_values[1], array_values[2], array_values[3], array_values[4], Time.new, nil)
            end
            if apply
              # Stores the item and requests the value
              cache[array_values[0]] = item
              value = socket.gets.chomp
              cache[array_values[0]].value = value
              socket.write("STORED\r\n") unless value.length > cache[array_values[0]].bytes.to_i
              socket.write("CLIENT_ERROR bad data chunk\r\n") unless value.length <= cache[array_values[0]].bytes.to_i
              cache.delete(array_values[0]) unless value.length <= cache[array_values[0]].bytes.to_i
            else
              socket.gets.chomp
              socket.write("NOT_STORED\r\n")
            end
          end
        end
      elsif request[0, 4].upcase == "GETS"
        unless cache.nil? then
          item_eval = cache[request[5, request.length]]
          if item_eval != nil && item_eval.exptime.to_i.positive? && (Time.new-item_eval.time).to_i >= item_eval.exptime.to_i
            cache.delete(request[5, request.length])
            true
          end
        end
        index = cache.find_index { |k,| k== request[5, request.length] }
        value = 'VALUE ' + request[5, request.length] + ' ' + cache[request[5, request.length]].to_s + ' ' + index.to_s + "\r\n" + cache[request[5, request.length]].get_value unless cache[request[5, request.length]].nil?
        socket.write(value) unless value.nil?
        socket.write("\r\n") unless value.nil?
        socket.write("END\r\n")

      elsif request[0, 3].upcase == "GET"
        unless cache.nil? && cache[request[4, request.length]].nil? then
          item_eval = cache[request[4, request.length]]
          if item_eval != nil && item_eval.exptime.to_i.positive? && (Time.new-item_eval.time).to_i >= item_eval.exptime.to_i
            cache.delete(request[4, request.length])
            true
          end
        end
        value = 'VALUE ' + request[4, request.length] + ' ' + cache[request[4, request.length]].to_s + "\r\n" + cache[request[4, request.length]].get_value unless cache[request[4, request.length]].nil?
        socket.write(value) unless value.nil?
        socket.write("\r\n") unless value.nil?
        socket.write("END\r\n")
      end
      request = nil
    end
    socket.write("Disconnecting from socket\r\n")
    socket.close
  end
end