# frozen_string_literal: true
require './memcached.rb'
memcached = Memcached.new(11211)
memcached.start
