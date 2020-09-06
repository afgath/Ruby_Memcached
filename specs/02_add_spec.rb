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
  describe '#add_no_args' do
    context 'adding without enough args' do
      it "returns error" do
        @socket.puts('add')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#add_exceed_args' do
    context 'adding exceeding max quantity of args' do
      it "returns error" do
        @socket.puts('add hello 0 0 5 3 2 1')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#add_non_existent_value' do
    context 'adding a non existent value' do
      it "returns STORED" do
        @socket.puts('add dataAddNoEx 0 20 6')
        sleep 1
        @socket.puts('Planet')
        expect(@socket.gets.chomp).to eql('STORED')
      end
    end
  end
  describe '#add_existent' do
    context 'adding element that already exists' do
      it "returns NOT_STORED" do
        @socket.puts('add dataAddNoEx 0 10 5')
        sleep 1
        @socket.puts('hello')
        expect(@socket.gets.chomp).to eql('NOT_STORED')
      end
    end
  end
end