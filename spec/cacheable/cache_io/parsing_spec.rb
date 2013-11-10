require 'spec_helper'

describe Cacheable do
	let(:object)  { User.create(:login => 'flyerhzm') }
	let(:coder) { {:class => object.class, 'attributes' => object.attributes} }
  let(:fixnum) { 11 }
  let(:string) { "string cheese" }
  let(:hash) { {a: 1, b: 2, c: 3} }
  let(:array) { ['a','b','c'] }
  let(:bool) { true }

  context "methods" do

  	it "should correctly determine if a Hash is a coder" do
  		Cacheable.hash_inspect(hash).should be_false
  		Cacheable.hash_inspect(coder).should be_true
  	end

    it "should detect coders and coders in arrays" do
      Cacheable.detect_coder(coder).should be_true
      Cacheable.detect_coder([coder]).should be_true
    end

  	it "should correctly rebuild objects from coders" do
  		Cacheable.parse_with_key(coder, :object).should == object
  	end

  	it "should rebuild multiple objects" do
      Cacheable.parse_with_key([coder, coder], :object).should == [object, object]
  	end

  	it "should parse only the values of method results" do
  		arg1 = Cacheable.symbolize_args([string,hash])
  		arg2 = Cacheable.symbolize_args([array,bool])
  		method_result = { arg1 => [coder],
  											arg2 => string }
      parsed = Cacheable.parse_with_key(method_result, :method)
      parsed[arg1].should == [object]
      parsed[arg2].should == string
  	end

  	it "should correctly parse methods without arguments" do
  		method_result = {"regular" => "hash"}
      Cacheable.parse_with_key(method_result, :method).should == method_result
  	end
  end
end
