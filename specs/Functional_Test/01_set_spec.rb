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
  describe '#set_no_args' do
    context 'setting without enough args' do
      it "returns error" do
        @socket.puts('set')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#set_exceed_args' do
    context 'setting exceeding the number of args' do
      it "returns error" do
        @socket.puts('set hello 0 0 5 3 4 5')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#set_correct' do
    context 'sending correct set command' do
      it "returns Stored" do
        @socket.puts('set data 0 0 5')
        sleep 1
        @socket.puts('hello')
        expect(@socket.gets.chomp).to eql('STORED')
      end
    end
  end
  describe '#set_correct_50_seconds' do
    context 'sending correct set command with 50 seconds duration' do
      it "returns Stored" do
        @socket.puts('set data50 0 50 8')
        sleep 1
        @socket.puts('Moove-It')
        expect(@socket.gets.chomp).to eql('STORED')
      end
    end
  end
  describe '#set_incorect_less_bytes' do
    context 'sending set command with less bytes than the data' do
      it "returns Error" do
        @socket.puts('set dataLess 0 50 5')
        sleep 1
        @socket.puts('More Than the bytes')
        expect(@socket.gets.chomp).to eql('CLIENT_ERROR bad data chunk')
      end
    end
  end
end