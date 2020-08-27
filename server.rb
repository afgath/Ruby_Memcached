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
      if request[0, 3].upcase == "SET"
        if request[4, request.length].nil?
          socket.write("ERROR")
        end
        array_values = request[4, request.length].split(" ")
        if array_values.count < 4 || array_values.count > 5
          socket.write("ERROR")
        else
          if array_values.count == 4 # If item hasn't setted the NoReply attribute
            item = Item.new(array_values[1], array_values[2], array_values[3], '', Time.new, nil)
          elsif array_values.count == 5 # If item has setted the NoReply attribute
            item = Item.new(array_values[1], array_values[2], array_values[3], array_values[4], Time.new, nil)
          end
          # Stores the item and requests the value
          cache[array_values[0]] = item
          value = socket.gets.chomp
          cache[array_values[0]].value = value
          socket.write("STORED\r\n")
        end
      elsif request[0, 4].upcase == "GETS"
        index = cache.find_index { |k,| k== request[5, request.length] }
        value = 'VALUE ' + request[5, request.length] + ' ' + cache[request[5, request.length]].to_s + ' ' + index.to_s + "\r\n" + cache[request[5, request.length]].get_value unless cache[request[5, request.length]].nil?
        socket.write(value) unless value.nil?
        socket.write("\r\n")
        socket.write("END\r\n")

      elsif request[0, 3].upcase == "GET"
        value = 'VALUE ' + request[4, request.length] + ' ' + cache[request[4, request.length]].to_s + "\r\n" + cache[request[4, request.length]].get_value unless cache[request[4, request.length]].nil?
        socket.write(value) unless value.nil?
        socket.write("\r\n")
        socket.write("END\r\n")
      end
      request = nil
    end
    socket.write("Disconnecting from socket\r\n")
    socket.close
  end
end

# def set(data)
#   array_values = data.split(" ")
#   if array_values.count < 4
#     return "Could not store because insufficient number of parameters"
#   elsif  array_values.count == 4
#     item = Item.new(array_values[1],array_values[2],null,null,array_values[3])
#     cache[array_values[1]] = item
#   end
#   return "STORED"
# end
