require 'rspec'
require 'socket'
class MemcachedDummy
end
describe MemcachedDummy do
  before(:example) do
    @host = 'localhost'     # The web server
    @port = 11211
    @socket = TCPSocket.open(@host, @port)
    sleep 1  #Allow server to start, so client doesn't send data
  end
  after(:example) do
    @socket.puts('quit')
  end
  describe '#replace_no_args' do
    context 'replacing without enough args' do
      it "returns error" do
        @socket.puts('replace')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#replace_exceed_args' do
    context 'replacing value exceeding max quantity of args' do
      it "returns error" do
        @socket.puts('replace hello 0 0 5 3 3 2 4')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#replace_existent_value' do
    context 'replacing a value that already exists' do
      it "returns STORED" do
        @socket.puts('set data 0 0 5')
        sleep 1
        @socket.puts('hello')
        sleep 1
        @socket.puts('replace data 0 0 6')
        sleep 1
        @socket.puts('Planet')
        expect(@socket.gets.chomp).to eql('STORED')
      end
    end
  end
  describe '#replace_non_existent_value' do
    context 'replacing a non existent value' do
      it "returns NOT_STORED" do
        @socket.puts('replace replace 0 0 5')
        sleep 1
        @socket.puts('Hello')
        expect(@socket.gets.chomp).to eql('NOT_STORED')
      end
    end
  end
end