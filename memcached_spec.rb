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
  describe '#add_no_args' do
    context 'adding without enough args' do
      it "returns error" do
        @socket.puts('add')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
  end
  describe '#replace_no_args' do
    context 'replacing without enough args' do
      it "returns error" do
        @socket.puts('replace')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
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
  describe '#cas_no_args' do
    context 'cas without enough args' do
      it "returns error" do
        @socket.puts('cas')
        expect(@socket.gets.chomp).to eql('ERROR')
      end
    end
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
  describe '#empty_command' do
    context 'sending an empty string' do
      it "returns error" do
        @socket.puts('')
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
  describe '#set_incorect_more_bytes' do
    context 'sending set command with more bytes than the data' do
      it "returns Error" do
        @socket.puts('set dataMore 0 0 30')
        sleep 1
        @socket.puts('Less Than the bytes')
        expect(@socket.gets.chomp).to eql('CLIENT_ERROR bad data chunk')
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
  describe '#cas_before_flush' do
    context 'cas data before timed flush ends' do
      it "returns STORED" do
        @socket.puts('cas data 0 0 14 4') # Se usa el mismo valor obtenido en el gets: 13
        sleep 1
        @socket.puts('Hello Moove-It')
        expect(@socket.gets.chomp).to eql("STORED")
      end
    end
  end
  describe '#cas_previously_modified' do
    context 'cas data when has been previously modified' do
      it "returns EXISTS" do
        @socket.puts('cas data 0 0 14 4') # Se usa el mismo valor obtenido en el gets: 13
        sleep 1
        @socket.puts('Hello Moove-It')
        expect(@socket.gets.chomp).to eql("EXISTS")
      end
    end
  end
  describe '#cas_non_existent_value' do
    context 'cas data when it does not exist' do
      it "returns NOT_FOUND" do
        @socket.puts('cas casNonEx 0 0 14 13') # Se usa el mismo valor obtenido en el gets: 13
        sleep 1
        @socket.puts('Hello Moove-It')
        expect(@socket.gets.chomp).to eql("NOT_FOUND")
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
  describe '#get_before_flush' do
    context 'get data before timed flush ends' do
      it "returns data" do
        @socket.puts('get dataAddNoEx')
        expect(@socket.gets.chomp).to eql("VALUE dataAddNoEx 0 6 ")
      end
    end
  end
  describe '#gets_before_flush' do
    context 'gets data before timed flush ends' do
      it "returns data_with_id" do
        @socket.puts('gets dataAddNoEx')
        expect(@socket.gets.chomp).to eql("VALUE dataAddNoEx 0 6  5")
      end
    end
  end
  describe '#append_to_value' do
    context 'appends introduced data after previous data' do
      it "returns STORED" do
        @socket.puts('append data 0 0 9') # Se usa el mismo valor obtenido en el gets: 13
        sleep 1
        @socket.puts(', Hire me')
        expect(@socket.gets.chomp).to eql("STORED")
      end
    end
  end
  describe '#prepend_to_value' do
    context 'prepends introduced data before previous data' do
      it "returns STORED" do
        @socket.puts('prepend data 0 0 4') # Se usa el mismo valor obtenido en el gets: 13
        sleep 1
        @socket.puts('Oh! ')
        expect(@socket.gets.chomp).to eql("STORED")
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