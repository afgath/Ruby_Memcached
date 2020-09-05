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
  describe '#delete_no_args' do
    context 'Try to exec a delete command without args' do
      it "returns ERROR" do
        @socket.puts('delete')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#delete_exceeding_args' do
    context 'Try to exec a delete command exceeding max args' do
      it "returns CLIENT ERROR" do
        @socket.puts('delete mykey exceed')
        expect(@socket.gets.chomp).to eql('CLIENT_ERROR bad command line format.')
      end
    end
  end
  describe '#delete_non-existent_value' do
    context 'Try delete a non-existent value' do
      it "returns NOT_FOUND" do
        @socket.puts('delete Mooveit')
        expect(@socket.gets.chomp).to eql('NOT_FOUND')
      end
    end
  end
  describe '#delete_existent_value' do
    context 'Try delete an existent value' do
      it "returns DELETED" do
        @socket.puts('set Mooveit 0 0 5')
        @socket.puts('hello')
        @socket.gets
        @socket.puts('delete Mooveit')
        expect(@socket.gets.chomp).to eql('DELETED')
      end
    end
  end
  describe '#flush_all_timing' do
    context 'Flush all in 1000 seconds' do
      it "returns OK" do
        @socket.puts('flush_all 1000')
        expect(@socket.gets.chomp).to eql('OK')
      end
    end
  end
  describe '#flush_all' do
    context 'Flush all now' do
      it "returns OK" do
        @socket.puts('flush_all')
        expect(@socket.gets.chomp).to eql('OK')
      end
    end
  end
end