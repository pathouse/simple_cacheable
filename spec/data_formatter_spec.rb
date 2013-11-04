require 'spec_helper'

describe Cacheable::DataFormatter::Formatter do
  let(:object)  { User.create(:login => 'flyerhzm') }
  let(:fixnum) { 11 }
  let(:string) { "string cheese" }
  let(:hash) { {a: 1, b: 2, c: 3} }
  let(:array) { ['a','b','c']}
  let(:bool) { true }

	it "should initialize with a cache miss result and a key type" do
		format = Cacheable::Formatter.new(object, :object)
		format.result.should == object
		format.key_type.should == :object
	end

	context "class methods" do

		it "should symbolize args correctly" do
			argsym = Cacheable::Formatter.symbolize_args([fixnum, string, hash, array])
			argsym.should == "11+string_cheese+a:1,b:2,c:3+a,b,c".to_sym
		end

		it "should escape method name punctuation correctly" do
			Cacheable::Formatter.escape_punctuation("holy_crap?").should == "holy_crap_query"
			Cacheable::Formatter.escape_punctuation("holy_crap!").should == "holy_crap_bang"
		end
	end

	context "instance methods" do

		it "should format objects correctly" do
			formatter = Cacheable::Formatter.new(object, :object)
			formatter.format.should == { :class => object.class, 'attributes' => object.attributes}
		end

		it "should format multiple object correctly" do
			coder = { :class => object.class, 'attributes' => object.attributes}
			formatter = Cacheable::Formatter.new([object, object], :association)
			formatter.format.should == [coder, coder]
		end

		it "should format methods without arguments correctly" do
			formatter = Cacheable::Formatter.new(fixnum, :method)
			formatter.format.should == 11
		end

		it "should format method with arguments correctly" do
			arg1 = Cacheable::Formatter.symbolize_args([fixnum,string,hash])
			arg2 = Cacheable::Formatter.symbolize_args([string,hash,fixnum])
			method_result = { arg1 => "answer1",
											  arg2 => "answer2" }
			formatter = Cacheable::Formatter.new(method_result, :method)
			formatter.format.should == method_result
		end

		it "should format object correctly when returned from a method" do
			arg1 = Cacheable::Formatter.symbolize_args([fixnum,string])
			method_result = { arg1 => object }
			formatter = Cacheable::Formatter.new(method_result, :method)
			formatter.format.should == { arg1 => {:class => object.class, 'attributes' => object.attributes} }
		end
	end
end





