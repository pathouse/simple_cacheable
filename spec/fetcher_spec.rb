require 'spec_helper'

describe Cacheable::CacheFetcher::Fetcher do
	let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }
  let(:user2) { User.create(:login => 'pathouse') }

	it "should initialize with object" do
		fetcher = Cacheable::Fetcher.new(object: user)
		fetcher.object.should == user
		fetcher.klass.should == user.class
	end

	it "should initialize with class" do
		fetcher = Cacheable::Fetcher.new(klass: user.class)
		fetcher.object.should == nil
		fetcher.klass.should == user.class
	end

	describe "read" do 

		let(:fetcher) { Cacheable::Fetcher.new(object: user) }
		let(:key_maker) { Cacheable::KeyMaker.new(object: user) }

		it "should successfully read one key" do
			user.cached_bad_iv_name!
			key = key_maker.method_key(:bad_iv_name!)
			fetcher.read_from_cache(key).should == 42
		end

		it "should successfully read multiple keys" do
			User.find_cached(user.id)
			User.find_cached(user2.id)

			keys = [key_maker.instance_key(user.id), key_maker.instance_key(user2.id)]
			keys = keys.map {|k| k[:key]}
			Rails.cache.read_multi(*keys).should == ""
		end

		it "should accept a block to define behavior on cache miss" do
		end
	end
end