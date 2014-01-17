require 'spec_helper'

describe Cacheable do
  let(:cache) { Rails.cache }

  before :all do
    @user     = User.create(:login => 'flyerhzm')
    @user2    =  User.create(:login => 'ScotterC')
    @post1    = @user.posts.create(:title => 'post1')
    @post2    = @user.posts.create(:title => 'post2')
    @post3    = Post.create
    @image1   = @post1.images.create
    @image2   = @post1.images.create
    @comment1 = @post1.comments.create
    @comment2 = @post1.comments.create
    @tag1     = @post1.tags.create(title: "Rails")
    @tag2     = @post1.tags.create(title: "Caching")
    @group1   = Group.create(name: "Ruby On Rails")
    @account  = @user.create_account(group: @group1)
    @location = @post1.create_location(city: "New York")
    @account_location = @account.create_account_location(city: "New Orleans")
    @account.save # @account doesn't persist location id?
  end

  before :each do
    @user.reload
    @post1.reload
  end

  context "with_association" do
    before :each do
      @post1.instance_variable_set("@cached_user", nil)
      @comment1.instance_variable_set("@cached_commentable", nil)
    end

    context "belongs_to" do
      it "should not cache association" do
        Rails.cache.read("users/#{@user.id}").should be_nil
      end

      it "should cache Post#user" do
        @post1.cached_user.should == @user
        Rails.cache.read("users/#{@user.id}").should == coder(@user)
      end

      it "should cache Post#user multiple times" do
        @post1.cached_user
        @post1.cached_user.should == @user
      end

      it "should not expire cached user on save" do
        Rails.cache.read("users/#{@user.id}").should be_nil
        @post1.cached_user.should == @user
        Rails.cache.read("users/#{@user.id}").should == coder(@user)
        @post1.save
        Rails.cache.read("users/#{@user.id}").should == coder(@user)
      end

      it "should cache Comment#commentable with polymorphic" do
        Rails.cache.read("posts/#{@post1.id}").should be_nil
        @comment1.cached_commentable.should == @post1
        Rails.cache.read("posts/#{@post1.id}").should == coder(@post1)
      end

      it "should return nil if there are none" do
        @post3.cached_user.should be_nil
      end
    end

    context "has_many" do
      it "should not cache associations" do
        Rails.cache.read("users/#{@user.id}/association/posts").should be_nil
      end

      it "should cache User#posts" do
        @user.cached_posts.should == [@post1, @post2]
        Rails.cache.read("users/#{@user.id}/association/posts").should == [coder(@post1), coder(@post2)]
      end

      it "should cache User#posts multiple times" do
        @user.cached_posts
        @user.cached_posts.should == [@post1, @post2]
      end

      it "should expire associations on save of associated objects" do
        pending #heisenbug.  When inspected it works fine
        Rails.cache.read("users/#{@user.id}/association/posts").should be_nil
        @user.cached_posts.should == [@post1, @post2]
        Rails.cache.read("users/#{@user.id}/association/posts").should_not be_nil
        @post1.save
        Rails.cache.read("users/#{@user.id}/association/posts").should be_nil
      end

      it "should expire associations on save of parent" do
        pending #heisenbug.  When inspected it works fine
        Rails.cache.read("users/#{@user.id}/association/posts").should be_nil
        @user.cached_posts.should == [@post1, @post2]
        Rails.cache.read("users/#{@user.id}/association/posts").should_not be_nil
        @user.save
        Rails.cache.read("users/#{@user.id}/association/posts").should be_nil
      end

      it "should return empty if there are none" do
        @user2.cached_posts.should == []
      end
    end

    context "has_many with polymorphic" do
      it "should not cache associations" do
        Rails.cache.read("posts/#{@post1.id}/association/comments").should be_nil
      end

      it "should cache Post#comments" do
        @post1.cached_comments.should == [@comment1, @comment2]
        Rails.cache.read("posts/#{@post1.id}/association/comments").should == [coder(@comment1), coder(@comment2)]
      end

      it "should cache Post#comments multiple times" do
        @post1.cached_comments
        @post1.cached_comments.should == [@comment1, @comment2]
      end

      it "should expire associations on save" do
        pending
        Rails.cache.read("posts/#{@post1.id}/association/comments").should be_nil
        @post1.cached_comments.should == [@comment1, @comment2]
        Rails.cache.read("posts/#{@post1.id}/association/comments").should == [coder(@comment1), coder(@comment2)]
        @post1.save
        Rails.cache.read("posts/#{@post1.id}/association/comments").should be_nil
      end

      it "should return empty if there are none" do
        @post3.cached_comments.should == []
      end
    end

    context "has_one" do
      it "should not cache associations" do
        Rails.cache.read("users/#{@user.id}/association/account").should be_nil
      end

      it "should cache User#posts" do
        @user.cached_account.should == @account
        Rails.cache.read("users/#{@user.id}/association/account").should == coder(@account)
      end

      it "should cache User#posts multiple times" do
        @user.cached_account
        @user.cached_account.should == @account
      end

      it "should expire association on save" do
        pending
        Rails.cache.read("users/#{@user.id}/association/account").should be_nil
        @user.cached_account.should == @account
        Rails.cache.read("users/#{@user.id}/association/account").should == coder(@account)
        @user.save
        Rails.cache.read("users/#{@user.id}/association/account").should be_nil
      end

      it "should return nil if there are none" do
        @user2.cached_account.should be_nil
      end
    end

    context "has_many through" do
      it "should not cache associations" do
        Rails.cache.read("users/#{@user.id}/association/images").should be_nil
      end

      it "should cache User#images" do
        @user.cached_images.should == [@image1, @image2]
        Rails.cache.read("users/#{@user.id}/association/images").should == [coder(@image1), coder(@image2)]
      end

      it "should cache User#images multiple times" do
        @user.cached_images
        @user.cached_images.should == [@image1, @image2]
      end

      it "should expire associations on save" do
        pending
        Rails.cache.read("users/#{@user.id}/association/images").should be_nil
        @user.cached_images.should == [@image1, @image2]
        Rails.cache.read("users/#{@user.id}/association/images").should == [coder(@image1), coder(@image2)]
        @user.save
        Rails.cache.read("users/#{@user.id}/association/images").should be_nil
      end

      context "expiry" do
        before :each do
          @user.instance_variable_set("@cached_images", nil)
        end

        it "should have the correct collection" do
          @image3 = @post1.images.create
          Rails.cache.read("users/#{@user.id}/association/images").should be_nil
          @user.cached_images.should == [@image1, @image2, @image3]
          Rails.cache.read("users/#{@user.id}/association/images").should == [coder(@image1),
                                                                             coder(@image2),
                                                                             coder(@image3)]
        end
      end

      it "should return empty if there are none" do
        @user2.cached_images.should == []
      end
    end

    context "has_one through belongs_to" do
      it "should not cache associations" do
        Rails.cache.read("users/#{@user.id}/association/group").should be_nil
      end

      it "should cache User#group" do
        @user.cached_group.should == @group1
        Rails.cache.read("users/#{@user.id}/association/group").should == coder(@group1)
      end

      it "should cache User#group multiple times" do
        @user.cached_group
        @user.cached_group.should == @group1
      end

      it "should expire association on save" do
        pending
        Rails.cache.read("users/#{@user.id}/association/group").should be_nil
        @user.cached_group.should == @group1
        Rails.cache.read("users/#{@user.id}/association/group").should == coder(@group1)
        @user.save
        Rails.cache.read("users/#{@user.id}/association/group").should be_nil
      end

      it "should return nil if there are none" do
        @user2.cached_group.should be_nil
      end

    end

    context "has_and_belongs_to_many" do

      it "should not cache associations off the bat" do
        Rails.cache.read("posts/#{@post1.id}/association/tags").should be_nil
      end

      it "should cache Post#tags" do
        @post1.cached_tags.should == [@tag1, @tag2]
        Rails.cache.read("posts/#{@post1.id}/association/tags").should == [coder(@tag1), coder(@tag2)]
      end

      it "should handle multiple requests" do
        @post1.cached_tags
        @post1.cached_tags.should == [@tag1, @tag2]
      end

      it "should expire association on save" do
        pending
        Rails.cache.read("posts/#{@post1.id}/association/tags").should be_nil
        @post1.cached_tags.should == [@tag1, @tag2]
        Rails.cache.read("posts/#{@post1.id}/association/tags").should == [coder(@tag1), coder(@tag2)]
        @post1.save
        Rails.cache.read("posts/#{@post1.id}/association/tags").should be_nil
      end

      it "should return empty if there are none" do
        @post3.cached_tags.should == []
      end

      context "expiry" do
        before :each do
          @post1.instance_variable_set("@cached_tags", nil)
        end

        it "should have the correct collection" do
          @tag3 = @post1.tags.create!(title: "Invalidation is hard")
          Rails.cache.read("posts/#{@post1.id}/association/tags").should be_nil
          @post1.cached_tags.should == [@tag1, @tag2, @tag3]
          Rails.cache.read("posts/#{@post1.id}/association/tags").should == [coder(@tag1),
                                                                             coder(@tag2),
                                                                             coder(@tag3)]
        end
      end
    end

  end

  describe "after_commit bug" do
    it "normal" do
      @image1.expects(:do_something).once
      @image1.save
    end

    it "new image fails without association" do
      image = Image.new
      image.expects(:do_something).once
      image.save
    end

    it "new image fails with missing association" do
      image = @group1.images.new
      image.expects(:do_something).once
      image.save
    end
  end

  describe "belongs_to bug" do

    it "shouldn't hit location" do
      @location.expects(:expire_association_cache).with(:images).never
      @user.save
    end

    context "with a user" do
      it "should not hit expire_association_cache on save" do
        account = Account.create
        user = User.new
        user.expects(:expire_association_cache)
        account.stubs(:user).returns user
        account.save
      end
    end

    context "without a user" do
      it "should not hit expire_association_cache on save" do
        account = Account.create
        obj = mock "object"
        obj.stubs(:nil?).returns true
        account.stubs(:user).returns obj
        obj.expects(:expire_association_cache).never
        account.expire_account_cache
      end

    end

  end

  # https://github.com/Shopify/identity_cache/pull/55/files
  describe "rails association cache" do
    it "should not load associated records" do
      @user.posts
      cached_user = User.find_cached(@user.id)
      cached_user.posts.loaded?.should be_false
    end
  end

  describe "memoization" do
    describe "belongs to" do
      before :each do
        @post1.instance_variable_set("@cached_user", nil)
        @post1.expire_model_cache
      end

      it "memoizes cache calls" do
        @post1.instance_variable_get("@cached_user").should be_nil
        @post1.cached_user.should == @post1.user
        @post1.instance_variable_get("@cached_user").should == @post1.user
      end

      it "hits the cache only once" do
        Rails.cache.expects(:read).returns(coder(@post1.user)).once
        @post1.cached_user.should == @post1.user
        @post1.cached_user.should == @post1.user
      end
    end

    describe "has through" do
      before :each do
        @user.instance_variable_set("@cached_images", nil)
        @user.expire_model_cache
      end

      it "memoizes cache calls" do
        @user.instance_variable_get("@cached_images").should be_nil
        @user.cached_images.should == @user.images
        @user.instance_variable_get("@cached_images").should == @user.images
      end

      it "hits the cache only once" do
        Rails.cache.expects(:read).returns(coder(@user.images)).once
        @user.cached_images.should == @user.images
        @user.cached_images.should == @user.images
      end
    end

    describe "has and belongs to many" do
      before :each do
        @post1.instance_variable_set("@cached_tags", nil)
        @post1.expire_model_cache
      end

      it "memoizes cache calls" do
        @post1.instance_variable_get("@cached_tags").should be_nil
        @post1.cached_tags.should == @post1.tags
        @post1.instance_variable_get("@cached_tags").should == @post1.tags
      end

      it "hits the cache only once" do
        Rails.cache.expects(:read).returns(coder(@post1.tags)).once
        @post1.cached_tags.should == @post1.tags
        @post1.cached_tags.should == @post1.tags
      end
    end

    describe "one to many" do
      before :each do
        @user.instance_variable_set("@cached_posts", nil)
        @user.expire_model_cache
      end

      it "memoizes cache calls" do
        @user.instance_variable_get("@cached_posts").should be_nil
        @user.cached_posts.should == @user.posts
        @user.instance_variable_get("@cached_posts").should == @user.posts
      end

      it "hits the cache only once" do
        Rails.cache.expects(:read).returns(coder(@user.posts)).once
        @user.cached_posts.should == @user.posts
        @user.cached_posts.should == @user.posts
      end
    end
  end

  describe "empty polymorphic" do
    let(:comment) { Comment.new }

    it "should save" do
      expect {
        comment.save
      }.to_not raise_exception
    end
  end

  describe "association class name bug" do
    it "should handle associations with different names" do
      @user.account.account_location.should == @account_location
      @user.cached_account.cached_account_location.should == @account_location
    end
  end

end