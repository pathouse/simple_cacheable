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

			key_blobs = [key_maker.instance_key(user.id), key_maker.instance_key(user2.id)]
			fetcher.read_multi_from_cache(key_blobs).should == [user, user2]
		end

		it "should successfully write one key" do
			key = key_maker.instance_key(user.id)
			fetcher.write_to_cache(key, user)
			Rails.cache.read(key[:key]).should == {:class => User, 'attributes' => user.attributes}
		end

		it "should successfully write multiple keys" do
			keys = []
			keys << key_maker.instance_key(user.id)
			keys << key_maker.instance_key(user2.id)
			write_blob = keys.zip([user,user2])
			fetcher.write_multi_to_cache(write_blob)
			Rails.cache.read_multi(*keys.map {|k| k[:key]}).should == {keys[0][:key] => {:class => User, 'attributes' => user.attributes},
																																 keys[1][:key] => {:class => User, 'attributes' => user2.attributes}}
		end
	end
end