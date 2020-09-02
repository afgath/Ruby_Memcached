require 'socket'
class Client
  host = 'localhost'     # The web server
  port = 1997                           # HTTP port
  path = "/index.htm"                 # The file we want
   request = "get"

  socket = TCPSocket.open(host,port)  # Connect to server
  socket.puts(request)           # Send request
  response = socket.gets.chomp              # Read complete response
  print response
end