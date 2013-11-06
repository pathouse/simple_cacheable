require 'spec_helper'

describe Cacheable do
  let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }
  let(:fetcher) { Cacheable::Fetcher.new(object: user) }

  before :each do
    cache.clear
    user.reload
  end

  it "should not cache key" do
    cache_key = Cacheable.instance_key(User, user.id)
    Rails.cache.read(cache_key[:key]).should be_nil
  end

  it "should cache by User#id" do
    User.find_cached(user.id).should == user
    cache_key = Cacheable.instance_key(User, user.id)
    Rails.cache.read(cache_key[:key]).should_not be_nil
  end

  it "should get cached by User#id multiple times" do
    User.find_cached(user.id)
    User.find_cached(user.id).should == user
  end

end