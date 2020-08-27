class Item
  attr_accessor :flags, :exptime, :bytes, :noreply, :time, :value

  def initialize(flags, exptime, bytes, noreply, time, value)
    @flags = flags
    @exptime = exptime
    @bytes = bytes
    @noreply = noreply
    @time = time
    @value = value
  end

  def to_s
    @flags + ' ' + @bytes + ' ' + @noreply
  end

  def get_time
    @exptime
  end
  def get_value
    @value
  end
  def get_creation_date
    @time
  end
end