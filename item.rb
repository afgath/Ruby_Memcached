class Item
  attr_accessor :flags, :exptime, :bytes, :noreply, :value

  def initialize(flags, exptime, bytes, noreply, value)
    @flags = flags
    @exptime = exptime
    @bytes = bytes
    @noreply = noreply
    @value = value
  end

  def to_s
    @flags + ' ' + @bytes + ' ' + @noreply + ' ' + @value
  end

  def get_time
    @exptime
  end
end