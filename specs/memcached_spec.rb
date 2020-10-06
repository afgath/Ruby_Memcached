# frozen_string_literal: true
require 'rspec'
require './Server/memcached'
require './Server/utils'

describe Memcached do
  before(:all) do
    @memcached = Memcached.new
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
end
