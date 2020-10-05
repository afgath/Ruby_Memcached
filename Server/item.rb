class Item
  attr_accessor :flags, :exptime, :bytes, :noreply, :time, :value, :id

  def initialize(flags, exptime, bytes, noreply, time, value, id)
    @flags = flags
    @exptime = exptime
    @bytes = bytes
    @noreply = noreply
    @time = time
    @value = value
    @id = id
  end

  def to_s
    @flags + ' ' + @bytes.to_s + ' ' + @noreply
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