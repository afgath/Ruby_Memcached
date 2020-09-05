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
  describe '#incr_no_args' do
    context 'incr without enough args' do
      it "returns error" do
        @socket.puts('incr')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#decr_no_args' do
    context 'decr without enough args' do
      it "returns error" do
        @socket.puts('decr')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#incr_exceed_args' do
    context 'incr exceeding max quantity of args' do
      it "returns error" do
        @socket.puts('incr hello d s')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#decr_exceed_args' do
    context 'decr exceeding max quantity of args' do
      it "returns error" do
        @socket.puts('decr hello 0 3 4')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#incr_numeric_value' do
    context 'increments a numeric value by the number entered' do
      it "returns new incremented value" do
        @socket.puts('set dataNum 0 0 2')
        sleep 1
        @socket.puts('25')
        sleep 1
        @socket.gets.chomp
        @socket.puts('incr dataNum 5')
        expect(@socket.gets.chomp).to eql("30")
      end
    end
  end
  describe '#decr_numeric_value' do
    context 'decrements a numeric value by the number entered' do
      it "returns new decremented value" do
        @socket.puts('set dataNum 0 0 2')
        sleep 1
        @socket.puts('25')
        sleep 1
        @socket.gets.chomp
        @socket.puts('decr dataNum 5')
        expect(@socket.gets.chomp).to eql("20")
      end
    end
  end
  describe '#incr_non_numeric_value' do
    context 'increments a non-numeric value by the number entered' do
      it "returns client error" do
        @socket.puts('set dataNonNum 0 0 2')
        sleep 1
        @socket.puts('Hi')
        sleep 1
        @socket.gets.chomp
        @socket.puts('incr dataNonNum 5')
        expect(@socket.gets.chomp).to eql("CLIENT_ERROR cannot increment or decrement non-numeric value")
      end
    end
  end
  describe '#decr_non_numeric_value' do
    context 'decrements a non-numeric value by the number entered' do
      it "returns client error" do
        @socket.puts('set dataNonNum 0 0 5')
        sleep 1
        @socket.puts('Hello')
        sleep 1
        @socket.gets.chomp
        @socket.puts('decr dataNonNum 5')
        expect(@socket.gets.chomp).to eql("CLIENT_ERROR cannot increment or decrement non-numeric value")
      end
    end
  end
  describe '#incr_numeric_value_with_non_numeric' do
    context 'increments a numeric value entering a character' do
      it "returns client error" do
        @socket.puts('set dataNum 0 0 2')
        sleep 1
        @socket.puts('25')
        sleep 1
        @socket.gets.chomp
        @socket.puts('incr dataNum k')
        expect(@socket.gets.chomp).to eql("CLIENT_ERROR invalid numeric delta argument")
      end
    end
  end
  describe '#decr_numeric_value_with_non_numeric' do
    context 'decrements a numeric value entering a character' do
      it "returns client error" do
        @socket.puts('set dataNum 0 0 2')
        sleep 1
        @socket.puts('25')
        sleep 1
        @socket.gets.chomp
        @socket.puts('decr dataNum m')
        expect(@socket.gets.chomp).to eql("CLIENT_ERROR invalid numeric delta argument")
      end
    end
  end
end