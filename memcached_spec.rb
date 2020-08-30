require 'rspec'
require './Memcached.rb'

describe Memcached do
  before(:example) do
    @server = Memcached.new(1997)

    Thread.new do
      @server.start
    end

    sleep 1  #Allow server to start, so client doesn't send data
    #to the server before the server creates the socket.

    @data = 'hello'
    @client.send_data @data  #Make sure server has started before doing this.
  end
end

after(:example) do
  @server.puts()
  #allowing recv_data() to finish executing.
  @server.client.close
end

describe '#handle_data' do
  context 'given a string' do
    it "returns reversed string" do
      expect(@server.handle_data(@data)).to eql(@data.reverse)
    end
  end
end