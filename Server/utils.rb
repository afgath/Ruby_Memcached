require_relative './item'
class Utils
  #Method that gets and validates the array with the header of the command
  def validate_headers(array_validate)
    # Generic Validations
    if array_validate.nil? || array_validate[0].nil?
      return BASIC_ERR
    end
    # Specific Validations
    case array_validate[0].upcase
    when DELETE
      if array_validate.length < 2
        BASIC_ERR
      elsif array_validate.length > 2
        LINE_FORMAT_ERR
      end
    when FLUSH_ALL
      if array_validate.length > 2
        BASIC_ERR
      end
    when INCR, DECR
      if array_validate.length != 3
        BASIC_ERR
      elsif array_validate[2].to_i.nil? || !array_validate[2].to_i.positive?
        NUMERIC_DELTA_ERR
      end
    when APPEND, PREPEND, SET, ADD, REPLACE
      if array_validate.length < 5 || array_validate.length > 6
        BASIC_ERR
      elsif array_validate[2].to_i.negative? || array_validate[3].to_i.negative? || array_validate[4].to_i < 1
        LINE_FORMAT_ERR
      end
    when CAS
      if array_validate.count < 6 || array_validate.count > 7
        BASIC_ERR
      end
    when GET, GETS
      if array_validate.length != 2
        BASIC_ERR
      end
    when QUIT
      if array_validate.length != 1
        BASIC_ERR
      end
    else
      BASIC_ERR
    end
  end
  def validate_value(bytes, value)
    if value == ''
      value = " \n"
    end
    if value.chomp != ''
      value = value.chomp
    end
    real_bytes = value.length
    if real_bytes == bytes.to_i
      true
    elsif real_bytes > bytes.to_i
      false
    else
      nil
    end
  end
  # Constants Section
  # Errors
  BASIC_ERR = "ERROR\r\n"
  LINE_FORMAT_ERR = "CLIENT_ERROR bad command line format.\r\n"
  NUMERIC_VAL_ERR = "CLIENT_ERROR cannot increment or decrement non-numeric value\r\n"
  NUMERIC_DELTA_ERR = "CLIENT_ERROR invalid numeric delta argument\r\n"
  CHUNK_ERR = "CLIENT_ERROR bad data chunk\r\n"
  EXISTS_ERR = "EXISTS\r\n"
  NOT_FOUND_ERR = "NOT_FOUND\r\n"
  # Messages
  STORED_MSG = "STORED\r\n"
  NOT_STORED_MSG = "NOT_STORED\r\n"
  OK_MSG = "OK\r\n"
  END_MSG = "END\r\n"
  DELETED_MSG = "DELETED\r\n"
  # Operations
  SET = 'SET'
  ADD = 'ADD'
  REPLACE = 'REPLACE'
  APPEND = 'APPEND'
  PREPEND = 'PREPEND'
  CAS = 'CAS'
  INCR = 'INCR'
  DECR = 'DECR'
  GET = 'GET'
  GETS = 'GETS'
  DELETE = 'DELETE'
  FLUSH_ALL = 'FLUSH_ALL'
  QUIT = 'QUIT'
end