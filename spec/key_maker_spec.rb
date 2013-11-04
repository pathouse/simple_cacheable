require 'spec_helper'

describe Cacheable::Keys::KeyMaker do
	let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }

	it "should initialize with object" do
		keymaker = Cacheable::KeyMaker.new(object: user)
		keymaker.object.should == user
		keymaker.klass.should == user.class
	end

	it "should initialize with class" do
		keymaker = Cacheable::KeyMaker.new(klass: user.class)
		keymaker.object.should be_nil
		keymaker.klass.should == user.class
	end

	context "keymaker methods" do
		let(:keymaker) { Cacheable::KeyMaker.new(object: user) }


		it "should create generation hash from model schema" do
			# this hash will change if User schema changes
			keymaker.model_generation.should == 12758287855206316690
		end

		it "should create generation hash from instance attributes" do
			# this hash will change if default user attributes change
			keymaker.instance_generation.should == 3897630690932324168
		end

		it "should create instance keys correctly" do
			expected_key = {type: :object,
											key: "users/12758287855206316690/#{user.id}"}
			keymaker.instance_key.should == expected_key
		end

		it "should create attribute keys correctly" do
			expected_key = {type: :attribute,
											key: "users/12758287855206316690/login:flyerhzm"}
			keymaker.attribute_key("login", "flyerhzm").should == expected_key
		end

		it "should create all attribute keys correctly" do
			expected_key = {type: :attribute,
											key: "users/12758287855206316690/all/login:flyerhzm"}
			keymaker.all_with_attribute_key("login", "flyerhzm").should == expected_key
		end

		it "should create method keys correctly" do
			expected_key = {type: :method,
											key: "users/12758287855206316690/#{user.id}/#{keymaker.instance_generation}/bad_iv_name!" }
			keymaker.method_key(:bad_iv_name!).should == expected_key
		end

		it "should create class method keys correctly" do
			expected_key = {type: :class_method,
											key: "users/12758287855206316690/user_with_id"}
			keymaker.class_method_key(:user_with_id).should == expected_key
		end

		it "should create association keys correctly" do
			expected_key = {type: :association,
											key: "users/12758287855206316690/#{user.id}/#{keymaker.instance_generation}/posts"}
			keymaker.association_key(:posts).should == expected_key
		end
	end
end