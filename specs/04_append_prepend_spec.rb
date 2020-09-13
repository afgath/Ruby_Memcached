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
  describe '#append_no_args' do
    context 'append without enough args' do
      it "returns error" do
        @socket.puts('append')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#prepend_no_args' do
    context 'prepend without enough args' do
      it "returns error" do
        @socket.puts('prepend')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#append_exceed_args' do
    context 'append value exceeding max quantity of args' do
      it "returns error" do
        @socket.puts('append hello 0 0 5 4 3 2 5')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#prepend_exceed_args' do
    context 'prepend exceeding max quantity of args' do
      it "returns error" do
        @socket.puts('prepend hello 0 0 6 3 2 1 4')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#append_to_value' do
    context 'appends introduced data after previous data' do
      it "returns STORED" do
        @socket.puts('set data 0 0 5')
        sleep 1
        @socket.puts('hello')
        @socket.puts('append data 0 0 9')
        sleep 1
        @socket.puts(', Hire me')
        expect(@socket.gets.chomp).to eql("STORED")
      end
    end
  end
  describe '#prepend_to_value' do
    context 'prepends introduced data before previous data' do
      it "returns STORED" do
        @socket.puts('prepend data 0 0 4')
        sleep 1
        @socket.puts('Oh! ')
        expect(@socket.gets.chomp).to eql("STORED")
      end
    end
  end
  describe '#append_exceed_value' do
    context 'appends data exceeding the number of bytes' do
      it "returns Client ERROR" do
        @socket.puts('set data 0 0 5')
        sleep 1
        @socket.puts('hello')
        @socket.gets
        @socket.puts('append data 0 0 9')
        sleep 1
        @socket.puts(', Hire mesdgfgfsdrt')
        expect(@socket.gets.chomp).to eql("CLIENT_ERROR bad data chunk")
      end
    end
  end
  describe '#prepend_exceed_value' do
    context 'prepends data exceeding the number of bytes' do
      it "returns Client ERROR" do
        @socket.puts('prepend data 0 0 4')
        sleep 1
        @socket.puts('Oh! sdgsdfgdf')
        expect(@socket.gets.chomp).to eql("CLIENT_ERROR bad data chunk")
      end
    end
  end
end