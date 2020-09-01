require 'socket'
require 'time'
require './item'


cache = {}
timer = nil
hostname = 'localhost'
port = 1997
server = TCPServer.open(hostname, port)
highest_id = 1

loop do
  Thread.start(server.accept) do |socket| # Multithread started so it can serve multiple clients
    request = socket.gets.chomp
    request = request[21, request.length]
    puts request
    loop do
      if request.nil? # Case: is not first command it receives the new interactions
        request = socket.gets.chomp
      end
      if request.upcase == "QUIT"
        break
      end
      puts request[4, request.length]
      valid = true # Value that indicates If item is valid
      array_validate = request.split(" ")
      if array_validate[2].to_i.negative? || array_validate[3].to_i.negative? || array_validate[4].to_i.negative?
        valid = false
      end
      item_validate = cache[array_validate[1]]
      if !item_validate.nil? && item_validate.exptime.to_i.positive? && (Time.new-item_validate.time).to_i >= item_validate.exptime.to_i
        cache.delete(array_validate[1])
      end
      exist_value = false
      exist_value = true unless cache[array_validate[1]].nil?
      if array_validate[0] == 'DELETE'
        if array_validate.length < 2
          socket.write("ERROR\r\n")
        elsif array_validate.length > 2
          socket.write("CLIENT_ERROR bad command line format.\r\n")
        elsif cache[array_validate[1]].nil?
          socket.write("NOT_FOUND\r\n")
        else
          cache.delete(array_validate[1])
          socket.write("DELETED\r\n")
        end
      elsif array_validate[0].upcase == 'FLUSH_ALL'
        if array_validate.length > 2
          socket.write("ERROR\r\n")
        else
          if !array_validate[1].to_i.nil?
            Thread.kill(timer) unless timer.nil?
            timer = Thread.new { sleep array_validate[1].to_i;; cache = {} }
          else
            cache = {}
          end
            socket.write("OK\r\n")
        end
      elsif array_validate[0].upcase == 'INCR' || array_validate[0].upcase == 'DECR'
        if array_validate.length != 3
          socket.write("ERROR\r\n")
        elsif !cache[array_validate[1]].value.to_i.nil? && cache[array_validate[1]].value.to_i.positive? && !array_validate[2].to_i.nil? && array_validate[2].to_i.positive?
          cache[array_validate[1]].value = (cache[array_validate[1]].value.to_i + array_validate[2].to_i).to_s unless array_validate[0].upcase == 'DECR'
          cache[array_validate[1]].value = (cache[array_validate[1]].value.to_i - array_validate[2].to_i).to_s unless array_validate[0].upcase == 'INCR'
          cache[array_validate[1]].value = '0' unless cache[array_validate[1]].value.to_i.positive?
          socket.write(cache[array_validate[1]].value + "\r\n")
        elsif cache[array_validate[1]].value.to_i.nil? || !cache[array_validate[1]].value.to_i.positive?
          socket.write("CLIENT_ERROR cannot increment or decrement non-numeric value\r\n")
        elsif array_validate[2].to_i.nil? || !array_validate[2].to_i.positive?
          socket.write("CLIENT_ERROR invalid numeric delta argument\r\n")
        end
      elsif array_validate[0].upcase == 'APPEND' || array_validate[0].upcase == 'PREPEND'
        if array_validate.length >= 5 && array_validate.length <= 6
          input = socket.gets.chomp
          if exist_value && input.to_s.length == array_validate[4].to_i && valid
            cache[array_validate[1]].value = cache[array_validate[1]].value.to_s + input.to_s unless array_validate[0].upcase == 'PREPEND'
            cache[array_validate[1]].value = input.to_s + cache[array_validate[1]].value.to_s unless array_validate[0].upcase == 'APPEND'
            cache[array_validate[1]].flags = array_validate[2]
            cache[array_validate[1]].exptime = array_validate[3]
            cache[array_validate[1]].bytes = (cache[array_validate[1]].bytes.to_i + array_validate[4].to_i).to_s
            cache[array_validate[1]].id = highest_id
            highest_id += 1
            socket.write("STORED\r\n")
          else
            socket.write("ERROR\r\n") unless exist_value && valid
            socket.write("CLIENT_ERROR bad data chunk\r\n") unless input.to_s.length == array_validate[4].to_i
          end
        else
          socket.write("ERROR\r\n")
        end

      elsif array_validate[0].upcase == 'CAS'
        mark_exists = false
        mark_notfound = false
        mark_wronglength = false
        if cache[array_validate[1]].nil?
          mark_notfound = true
        elsif cache[array_validate[1]].id.to_i != array_validate[5].to_i
          mark_exists = true
        end
        if array_validate.count > 5 && array_validate.count < 7
          value = socket.gets.chomp
          if array_validate[4].to_i != value.length
            mark_wronglength = true
          end
          if mark_exists || mark_notfound || mark_wronglength
            socket.write("EXISTS\r\n") unless mark_notfound || mark_wronglength
            socket.write("NOT_FOUND\r\n") unless  mark_exists || mark_wronglength
            socket.write("CLIENT_ERROR bad data chunk\r\n") unless  mark_exists || mark_notfound
          else
            cache[array_validate[1]].flags = array_validate[2]
            cache[array_validate[1]].exptime = array_validate[3]
            cache[array_validate[1]].bytes = array_validate[4]
            cache[array_validate[1]].noreply = array_validate[5]
            cache[array_validate[1]].time = Time.new
            cache[array_validate[1]].value = value
            cache[array_validate[1]].id = highest_id
            highest_id += 1
            socket.write("STORED\r\n")
          end

        else
          socket.write("ERROR\r\n")
        end

      elsif array_validate[0].upcase == 'REPLACE' || array_validate[0].upcase == 'SET' || array_validate[0].upcase == 'ADD'
        apply = true # value that indicates If the operation applies
        if request[4, request.length].nil?
          socket.write("ERROR\r\n")
          valid = false
        end
        if array_validate[0].upcase == 'REPLACE'
          array_values = request[8, request.length].split(" ")
        else
          array_values = request[4, request.length].split(" ")
        end
        if request[0, 3].upcase == 'ADD' && cache.any? # If command=add then key must not exist
          apply = false unless cache[array_values[0]].nil?
        end
        if array_validate[0].upcase == 'REPLACE' && cache[array_values[0]].nil? # If command=replace then key must exist
          apply = false
        end
        if array_values.count < 4 || array_values.count > 5 || !valid
          socket.write("ERROR\r\n")
        else
          if valid
            if array_values.count == 4 # If item hasn't set the NoReply attribute
              item = Item.new(array_values[1], array_values[2], array_values[3], '', nil , nil, 0)
            elsif array_values.count == 5 # If item has set the NoReply attribute
              item = Item.new(array_values[1], array_values[2], array_values[3], array_values[4], nil , nil, 0)
            end
            if apply
              # Stores the item and requests the value
              item.id = highest_id unless cache[array_values[0]].nil?
              cache[array_values[0]] = item
              value = socket.gets.chomp
              cache[array_values[0]].value = value
              cache[array_values[0]].time = Time.new
              highest_id += 1 unless value.length != cache[array_values[0]].bytes.to_i
              socket.write("STORED\r\n") unless value.length > cache[array_values[0]].bytes.to_i
              socket.write("CLIENT_ERROR bad data chunk\r\n") unless value.length == cache[array_values[0]].bytes.to_i
              cache.delete(array_values[0]) unless value.length == cache[array_values[0]].bytes.to_i
            else
              socket.gets.chomp
              socket.write("NOT_STORED\r\n")
            end
          end
        end
      elsif array_validate[0].upcase == 'GETS'
        value = 'VALUE ' + request[5, request.length] + ' ' + cache[request[5, request.length]].to_s + ' ' + cache[request[5, request.length]].id.to_s + "\r\n" + cache[request[5, request.length]].get_value unless cache[request[5, request.length]].nil?
        socket.write(value) unless value.nil?
        socket.write("\r\n") unless value.nil?
        socket.write("END\r\n")

      elsif array_validate[0].upcase == 'GET'
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