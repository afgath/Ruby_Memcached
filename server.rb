require 'socket'
require 'time'
require './item'

cache = {}
hostname = 'localhost'
port = 1997

server = TCPServer.open(hostname, port)

loop do
  socket = server.accept
  request = socket.gets.chomp
  puts request
  puts request[0,3]
  puts request[4,request.length]
  if request[0,3].upcase == "SET"
    array_values = request[4,request.length].split(" ")
    if array_values.count < 4
      socket.write("Could not store because insufficient number of parameters")
    elsif  array_values.count == 4
      item = Item.new(array_values[1],array_values[2],array_values[3],'',nil)
      cache[array_values[0]] = item
      value = socket.gets.chomp
      cache[array_values[0]].value = value
      socket.write("STORED")
    end
  elsif request[0,3].upcase == "GET"
    value = cache[request[4,request.length]]
    socket.write(value) unless value.nil?
    socket.write()
  end
  socket.close
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