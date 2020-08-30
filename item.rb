class Item
  attr_accessor :flags, :exptime, :bytes, :noreply, :time, :value , :modified, :id

  def initialize(flags, exptime, bytes, noreply, time, value, modified)
    @flags = flags
    @exptime = exptime
    @bytes = bytes
    @noreply = noreply
    @time = time
    @value = value
    @modified = modified
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