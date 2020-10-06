# frozen_string_literal: true
require 'rspec'
require_relative '../Server/memcached'
require_relative '../Server/utils'

describe Memcached do
  before(:all) do
    @memcached = Memcached.new
    @utils = Utils.new
  end
  describe "set item" do
    array_validate = %w[set data 0 0 5]
    value = 'hello'
    it "sets a new item to memcache" do
      expect(@memcached.save(array_validate, value)).to eq(Utils::STORED_MSG)
    end
  end
  describe 'add items' do
    context 'given a non existent item' do
      it 'adds the new item to the memcache' do
        array_validate = %w[add data2 0 0 5]
        value = 'hello'
        expect(@memcached.save(array_validate, value)).to eq(Utils::STORED_MSG)
      end
    end
    context 'given an existent item' do
      it 'throws error because you can only add nonexistent values' do
        array_validate = %w[add data 0 0 5]
        value = 'hello'
        expect(@memcached.save(array_validate, value)).to eq(Utils::NOT_STORED_MSG)
      end
    end
  end
  describe 'replace items' do
    context 'given a non existent item' do
      it 'throws error because you cannot replace a nonexistent value' do
        array_validate = %w[replace data3 0 0 5]
        value = 'hello'
        expect(@memcached.save(array_validate, value)).to eq(Utils::NOT_STORED_MSG)
      end
    end
    context 'given an existent item' do
      it 'replaces the current item value' do
        array_validate = %w[replace data 0 0 5]
        value = 'hello'
        expect(@memcached.save(array_validate, value)).to eq(Utils::STORED_MSG)
      end
    end
  end
  describe 'delete items' do
    context 'given a non existent item' do
      it 'throws error because you cannot delete a nonexistent value' do
        array_validate = %w[delete dataNoEx 0 0 5]
        expect(@memcached.delete(array_validate)).to eq(Utils::NOT_FOUND_ERR)
      end
    end
    context 'given an existent item' do
      it 'deletes the item' do
        array_validate = %w[delete data]
        expect(@memcached.delete(array_validate)).to eq(Utils::DELETED_MSG)
      end
    end
  end
  describe 'concat to items' do
    context 'given a non existent item' do
      it 'throws error because there has to be an item in the cache to concat the value' do
        array_validate = %w[append dataExNo 0 0 5]
        value = 'hello'
        expect(@memcached.concat(array_validate, value)).to eq(Utils::NOT_STORED_MSG)
      end
    end
    context 'given an existent item' do
      it 'concatenates the word before or after depending the command' do
        array_validate = %w[prepend data2 0 0 5]
        value = 'hello'
        expect(@memcached.concat(array_validate, value)).to eq(Utils::STORED_MSG)
      end
    end
  end
  describe 'cas items' do
    context 'given a non existent item' do
      it 'throws error because there has to be an item in the cache to complete this operation' do
        array_validate = %w[cas dataExNo 0 0 5 5]
        value = 'hello'
        expect(@memcached.cas(array_validate, value)).to eq(Utils::NOT_FOUND_ERR)
      end
    end
    context 'given an existent item not previously modified' do
      it 'replaces the item' do
        array_validate = %w[cas data2 0 0 2 4]
        value = '15'
        expect(@memcached.cas(array_validate, value)).to eq(Utils::STORED_MSG)
      end
    end
    context 'given an existent item previously modified' do
      it 'informs that the item already exists' do
        array_validate = %w[cas data2 0 0 5 4]
        value = 'hello'
        expect(@memcached.cas(array_validate, value)).to eq(Utils::EXISTS_ERR)
      end
    end
  end
  describe 'incr_decr to the value of a memcache item' do
    context 'given a non existent item' do
      it 'throws error because there has to be an item in the cache to concat the value' do
        array_validate = %w[incr dataExNo 15]
        expect(@memcached.incr_decr(array_validate)).to eq(Utils::NOT_FOUND_ERR)
      end
    end
    context 'given an existent item with numeric value' do
      it 'does the incr/decr operation as the command says' do
        array_validate = %w[incr data2 15]
        expect(@memcached.incr_decr(array_validate).chomp).to eq('30')
      end
    end
    context 'given an existent item with non-numeric value' do
      it 'throws non numeric value error' do
        @memcached.save(%w[set data 0 0 5], 'hello')
        array_validate = %w[incr data 15]
        expect(@memcached.incr_decr(array_validate)).to eq(Utils::NUMERIC_VAL_ERR)
      end
    end
    context 'given an non-numeric new value to the item' do
      it 'throws non numeric delta trying to be added error' do
        array_validate = %w[incr data2 lol]
        expect(@memcached.incr_decr(array_validate)).to eq(Utils::NUMERIC_DELTA_ERR)
      end
    end
  end
  describe 'get/s items' do
    context 'given a non existent item' do
      it 'returns nil' do
        array_validate = %w[get dataExNo]
        expect(@memcached.get(array_validate)).to eq(nil)
      end
    end
    context 'given an existent item' do
      it 'gets the item info and value without the Id' do
        array_validate = %w[get data2]
        expect(@memcached.get(array_validate).chomp).to eq("VALUE data2 0 2 \r\n30")
      end
    end
    context 'given an existent item' do
      it 'gets the item info and value with the Id' do
        array_validate = %w[gets data2]
        expect(@memcached.get(array_validate).chomp).to eq("VALUE data2 0 2  6\r\n30")
      end
    end
  end
  describe 'flush items on cache' do
    it 'flushes item within specified seconds' do
      array_validate = %w[flush_all 30]
      expect(@memcached.flush_all(array_validate)).to eq(Utils::OK_MSG)
    end
    it 'flushes item right away' do
      array_validate = %w[flush_all]
      expect(@memcached.flush_all(array_validate)).to eq(Utils::OK_MSG)
    end
  end
  # Start of Utils Section
  describe 'validate values vs bytes' do
    context 'given 5 bytes and a 5 characters word' do
      it 'returns true because the length of the word = bytes' do
        bytes = 5
        value = 'hello'
        expect(@utils.validate_value(bytes, value)).to eq(true)
      end
    end
    context 'given 5 bytes and a 6 characters word' do
      it 'returns false because the length of the word > bytes' do
        bytes = 5
        value = 'hellos'
        expect(@utils.validate_value(bytes, value)).to eq(false)
      end
    end
    context 'given 5 bytes and a 4 characters word' do
      it 'returns nil because the length of the word < bytes and it expects more chars in the word' do
        bytes = 5
        value = 'well'
        expect(@utils.validate_value(bytes, value)).to eq(nil)
      end
    end
  end
  describe 'validate headers of the memcached command' do
    context 'given nil headers array' do
      it 'throws basic error because the array is empty' do
        array_validate = nil
        expect(@utils.validate_headers(array_validate)).to eq(Utils::BASIC_ERR)
      end
    end
    context 'given 1 header in delete statement' do
      it 'throws basic error because there are no enough headers' do
        array_validate = %w[delete]
        expect(@utils.validate_headers(array_validate)).to eq(Utils::BASIC_ERR)
      end
    end
    context 'given 5 headers in delete statement' do
      it 'throws error because it has excessive headers' do
        array_validate = %w[delete j 0 5 3]
        expect(@utils.validate_headers(array_validate)).to eq(Utils::LINE_FORMAT_ERR)
      end
    end
    context 'given 2 headers in delete statement' do
      it 'returns nil because statement is correct' do
        array_validate = %w[delete j]
        expect(@utils.validate_headers(array_validate)).to eq(nil)
      end
    end
    context 'given 3 headers in flush_all statement' do
      it 'throws error because it has excessive headers' do
        array_validate = %w[flush_all j 0]
        expect(@utils.validate_headers(array_validate)).to eq(Utils::BASIC_ERR)
      end
    end
    context 'given 1 header in flush_all statement' do
      it 'returns nil because is correct' do
        array_validate = %w[flush_all]
        expect(@utils.validate_headers(array_validate)).to eq(nil)
      end
    end
    context 'given 2 headers in flush_all statement' do
      it 'returns nil because is correct' do
        array_validate = %w[flush_all 300]
        expect(@utils.validate_headers(array_validate)).to eq(nil)
      end
    end
    context 'given more than 3 headers on incr/decr statement' do
      it 'throws error because it has excessive headers' do
        array_validate = %w[incr j 6 4 3]
        expect(@utils.validate_headers(array_validate)).to eq(Utils::BASIC_ERR)
      end
    end
    context 'given less than 3 headers on incr/decr statement' do
      it 'throws error because it has excessive headers' do
        array_validate = %w[decr j]
        expect(@utils.validate_headers(array_validate)).to eq(Utils::BASIC_ERR)
      end
    end
    context 'given a non numeric value to incr/decr' do
      it 'throws error because it only can incr/decr numeric values' do
        array_validate = %w[decr j ref]
        expect(@utils.validate_headers(array_validate)).to eq(Utils::NUMERIC_DELTA_ERR)
      end
    end
    context 'given a numeric value to incr/decr' do
      it 'returns nil because statement is correct' do
        array_validate = %w[decr j 15]
        expect(@utils.validate_headers(array_validate)).to eq(nil)
      end
    end
    context 'given all non numeric headers to set statement' do
      it 'throws error because flags, time and bytes must be numeric' do
        array_validate = %w[set j i oe w]
        expect(@utils.validate_headers(array_validate)).to eq(Utils::LINE_FORMAT_ERR)
      end
    end
  end
end
