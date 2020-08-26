require 'socket'

host = 'localhost'     # The web server
port = 1997                           # Default HTTP port
path = "/index.htm"                 # The file we want

# This is the HTTP request we send to fetch a file
request = "set miLlave 0 200 Buenas"

socket = TCPSocket.open(host,port)  # Connect to server
socket.puts(request)           # Send request
response = socket.read              # Read complete response
print response                          # And display it

request = "get miLlave"

socket = TCPSocket.open(host,port)  # Connect to server
socket.puts(request)           # Send request
response = socket.read              # Read complete response
print response