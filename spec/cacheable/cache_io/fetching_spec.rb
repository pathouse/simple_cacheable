require 'spec_helper'

describe Cacheable do
	let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }
  let(:user2) { User.create(:login => 'pathouse') }

	describe "read" do 

		it "should successfully read one key" do
			user.cached_bad_iv_name!
			key = Cacheable.method_key(user, :bad_iv_name!)
			Cacheable.read_from_cache(key).should == 42
		end

		it "should successfully read multiple keys" do
			User.find_cached(user.id)
			User.find_cached(user2.id)

			key_blobs = [Cacheable.instance_key(user.class, user.id), 
									 Cacheable.instance_key(user2.class, user2.id)]
			Cacheable.read_multi_from_cache(key_blobs).should == {key_blobs[0][:key] => user, 
																														key_blobs[1][:key] => user2}
		end

		it "should successfully write one key" do
			key = Cacheable.instance_key(user.class, user.id)
			Cacheable.write_to_cache(key, user)
			Rails.cache.read(key[:key]).should == {:class => User, 'attributes' => user.attributes}
		end

		it "should successfully write multiple keys" do
			keys = []
			keys << Cacheable.instance_key(user.class, user.id)
			keys << Cacheable.instance_key(user2.class, user2.id)
			Cacheable.write_multi_to_cache({keys[0] => user, keys[1] => user2})
			Rails.cache.read_multi(*keys.map {|k| k[:key]}).should == {keys[0][:key] => {:class => User, 'attributes' => user.attributes},
																																 keys[1][:key] => {:class => User, 'attributes' => user2.attributes}}
		end
	end
end