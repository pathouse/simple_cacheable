require 'spec_helper'

describe Cacheable::DataInterpreter::Interpreter do
	let(:object)  { User.create(:login => 'flyerhzm') }
	let(:coder) { {:class => object.class, 'attributes' => object.attributes} }
  let(:fixnum) { 11 }
  let(:string) { "string cheese" }
  let(:hash) { {a: 1, b: 2, c: 3} }
  let(:array) { ['a','b','c'] }
  let(:bool) { true }

  it "should initialize with a cache read result and a key type" do
  	interpreter = Cacheable::Interpreter.new(coder, :object)
  	interpreter.result.should == coder
  	interpreter.key_type.should == :object
  end

  context "class methods" do

  	it "should correctly determine if a Hash is a coder" do
  		Cacheable::Interpreter.hash_inspect(hash).should be_false
  		Cacheable::Interpreter.hash_inspect(coder).should be_true
  	end
  end

  context "instance methods" do

  	it "should correctly rebuild objects from coders" do
  		interpreter = Cacheable::Interpreter.new(coder, :object)
  		interpreter.interpret.should == object
  	end

  	it "should rebuild multiple objects" do
  		interpreter = Cacheable::Interpreter.new([coder, coder], :association)
  		interpreter.interpret.should == [object, object]
  	end

  	it "should parse only the values of method results" do
  		arg1 = Cacheable::Formatter.symbolize_args([string,hash])
  		arg2 = Cacheable::Formatter.symbolize_args([array,bool])
  		method_result = { arg1 => coder,
  											arg2 => string }
  		interpreter = Cacheable::Interpreter.new(method_result, :method)
  		interpreter.interpret.should == { arg1 => object, arg2 => string }
  	end

  	it "should correctly parse methods without arguments" do
  		method_result = {"regular" => "hash"}
  		interpreter = Cacheable::Interpreter.new(method_result, :method)
  		interpreter.interpret.should == method_result
  	end

  end
end
