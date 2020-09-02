require 'rspec'
require 'socket'
class MemcachedDummy
end
describe MemcachedDummy do
  before(:example) do
    @host = 'localhost'     # The web server
    @port = 1997
    @socket = TCPSocket.open(@host, @port)
    sleep 1  #Allow server to start, so client doesn't send data
  end
  describe '#set_no_args' do
    context 'setting without enough args' do
      it "returns error" do
        @socket.puts('set')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
end

# after(:example) do
#   @server.puts()
# end