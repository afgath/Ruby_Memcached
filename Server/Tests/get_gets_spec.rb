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
  describe '#get_no_args' do
    context 'getting without enough args' do
      it "returns error" do
        @socket.puts('get')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#gets_no_args' do
    context 'gets without enough args' do
      it "returns error" do
        @socket.puts('gets')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#get_exceed_args' do
    context 'getting exceeding max quantity of args' do
      it "returns error" do
        @socket.puts('get hello hj 3')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#gets_exceed_args' do
    context 'gets exceeding max number of args' do
      it "returns error" do
        @socket.puts('gets hello 0 3 4')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#get_before_flush' do
    context 'get data before timed flush ends' do
      it "returns data" do
        @socket.puts('flush_all')
        @socket.gets
        @socket.puts('add dataAddNoEx 0 10 5')
        sleep 1
        @socket.puts('hello')
        @socket.gets
        @socket.puts('get dataAddNoEx')
        expect(@socket.gets.chomp).to eql("VALUE dataAddNoEx 0 5 ")
      end
    end
  end
  describe '#gets_before_flush' do
    context 'gets data before timed flush ends' do
      it "returns data_with_id" do
        @socket.puts('gets dataAddNoEx')
        expect(@socket.gets.chomp).to eql("VALUE dataAddNoEx 0 5  1")
      end
    end
  end
end