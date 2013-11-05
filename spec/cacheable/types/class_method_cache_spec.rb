require 'spec_helper'

describe Cacheable do
  let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm', :email => 'flyerhzm@mail.com') }

  let(:post_key_maker) { Cacheable::KeyMaker.new(object: @post1) }

  before :all do
    @post1 = user.posts.create(:title => 'post1')
    @post2 = user.posts.create(:title => 'post2')
  end

  before :each do
    cache.clear
    user.reload
  end

  it "should not cache Post.default_post" do
    key = post_key_maker.class_method_key(:default_post)
    Rails.cache.read(key[:key]).should be_nil
  end

  it "should cache Post.default_post" do
    key = post_key_maker.class_method_key(:default_post)
    Post.cached_default_post.should == @post1
    Rails.cache.read(key[:key]).should == {:class => @post1.class, 'attributes' => @post1.attributes}
  end

  it "should cache Post.default_post multiple times" do
    Post.cached_default_post
    Post.cached_default_post.should == @post1
  end

  it "should cache Post.retrieve_with_user_id" do
    Post.cached_retrieve_with_user_id(1).should == @post1
    key = post_key_maker.class_method_key(:retrieve_with_user_id)
    Rails.cache.read(key[:key]).should == {:"1" => {:class => @post1.class, 'attributes' => @post1.attributes }}
  end

  it "should cache Post.retrieve_with_both with multiple arguments" do
    Post.cached_retrieve_with_both(1, 1).should be_true
    key = post_key_maker.class_method_key(:retrieve_with_both)
    Rails.cache.read(key[:key]).should == { :"1+1" => true }
  end

  describe "marshalling" do
    let (:user_key_maker) { Cacheable::KeyMaker.new(object: user) }

    it "should handle methods with a number argument" do
      result = User.cached_user_with_id(1)
      key = user_key_maker.class_method_key(:user_with_id)
      Rails.cache.read(key[:key]).should == {:"1" => {:class => user.class, 'attributes' => user.attributes }}
    end

    it "should handle methods with a string argument" do
      result = User.cached_user_with_email("flyerhzm@mail.com")
      key = user_key_maker.class_method_key(:user_with_email)
      Rails.cache.read(key[:key]).should == {:"flyerhzm@mail.com" => {:class => user.class, 'attributes' => user.attributes} }
    end

    it "should handle methods with an array argument" do
      result = User.cached_users_with_ids([ 1 ])
      key = user_key_maker.class_method_key(:users_with_ids)
      Rails.cache.read(key[:key]).should == {:"1" => [{:class => user.class, 'attributes' => user.attributes}]}
    end

    it "should handle methods with a range argument" do
      result = User.cached_users_with_ids_in( (1...3) )
      key = User.class_method_cache_key("users_with_ids_in", (1...3))
      Rails.cache.read(key[:key]).should == result
    end
  end
end