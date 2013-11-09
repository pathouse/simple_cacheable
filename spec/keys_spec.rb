require 'spec_helper'

describe Cacheable do
	let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }

	context "methods" do
		let(:keymaker) { Cacheable::KeyMaker.new(object: user) }

		it "should generate a model prefix" do
			schema_string = User.columns.sort_by(&:name).map { |c| "#{c.name}:#{c.type}"}.join(",")
			schema_hash = CityHash.hash64(schema_string)
			prefix = Cacheable.model_prefix(User)
			prefix.should == "users/#{schema_hash}"
		end

		it "should generate an instance prefix" do
			attribute_string = user.attributes.sort.map { |k,v| [k,v].join(":")}.join(",")
			attribute_hash = CityHash.hash64(attribute_string)
			prefix = Cacheable.instance_prefix(user)
			prefix.should == Cacheable.model_prefix(User) + "/#{user.id.to_s}/#{attribute_hash}"
		end

		it "should generate an instance key" do
			expected_key = {type: :object, key: Cacheable.model_prefix(User) + "/#{user.id.to_s}"}
			Cacheable.instance_key(User, user.id).should == expected_key
		end

		it "should generate an attribute key" do
			expected_key = {type: :object, key: Cacheable.model_prefix(User) + '/login/pathouse'}
			att_key = Cacheable.attribute_key(User, :login, ['pathouse'])
			att_key.should == expected_key
		end

		it "should generate an all w/ attribute key" do
			expected_key = {type: :association, key: Cacheable.model_prefix(User) + "/all/login/pathouse"}
			att_key = Cacheable.attribute_key(User, :login, ['pathouse'], all: true)
			att_key.should == expected_key
		end

		it "should generate a class method key" do
			expected_key = {type: :method, key: Cacheable.model_prefix(User) + "/default_name"}
			cmethod_key = Cacheable.class_method_key(User, :default_name)
			cmethod_key.should == expected_key
		end

		it "should return all class method keys" do
			all_cmethod_keys = Cacheable.all_class_method_keys(User)
			comparison = User.cached_class_methods.map do |cmeth|
				Cacheable.class_method_key(User, cmeth)
			end
			all_cmethod_keys.should == comparison
		end

		it "should generate a method key" do
			expected_key = {type: :method, key: Cacheable.instance_prefix(user) + "/last_post"}
			method_key = Cacheable.method_key(user, :last_post)
			method_key.should == expected_key
		end

		it "should generate an association key" do
			expected_key = {type: :association, key: Cacheable.instance_prefix(user) + "/posts"}
			assoc_key = Cacheable.association_key(user, :posts)
			assoc_key.should == expected_key
		end
	end
end