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
  describe '#cas_no_args' do
    context 'cas without enough args' do
      it "returns error" do
        @socket.puts('cas')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#cas_exceed_args' do
    context 'cas exceeding max quantity of args' do
      it "returns error" do
        @socket.puts('cas hello 0 0 2 4 5 6')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#cas_data' do
    context 'cas data' do
      it "returns STORED" do
        @socket.puts('flush_all')
        sleep 3
        @socket.puts('set dataCas 0 0 5')
        @socket.puts('hello')
        @socket.gets
        @socket.puts('cas dataCas 0 0 14 1')
        @socket.puts('Hello Moove-It')
        expect(@socket.gets.chomp).to eql("STORED")
      end
    end
  end
  describe '#cas_previously_modified' do
    context 'cas data when has been previously modified' do
      it "returns EXISTS" do
        @socket.puts('cas dataCas 0 0 14 1')
        sleep 1
        @socket.puts('Hello Moove-It')
        expect(@socket.gets.chomp).to eql("EXISTS")
      end
    end
  end
  describe '#cas_non_existent_value' do
    context 'cas data when it does not exist' do
      it "returns NOT_FOUND" do
        @socket.puts('cas casNonEx 0 0 14 13')
        sleep 1
        @socket.puts('Hello Moove-It')
        expect(@socket.gets.chomp).to eql("NOT_FOUND")
      end
    end
  end
end