require 'gitolite/dirty_proxy'
require 'spec_helper'

describe Gitolite::DirtyProxy do

  it "should create a new instance given valid attributes" do
    Gitolite::DirtyProxy.new([]).should_not be_nil
  end

  let(:target) { ['foo', 'bar'] }
  let(:proxy) { Gitolite::DirtyProxy.new(target) }

  describe 'delegating to the target object' do
    it 'should act as instance of the target' do
      proxy.should be_instance_of target.class
    end

    it 'should respond to all methods of the target' do
      proxy.should respond_to(*target.methods)
    end

    it 'should equal the target' do
      proxy.should equal target
    end
  end

  describe 'dirty checking methods' do
    it 'should respond to clean_up!' do
      proxy.respond_to?(:clean_up!).should be_true
    end

    it 'should respond to dirty?' do
      proxy.respond_to?(:dirty?).should be_true
    end

    context 'when just initialized' do
      it 'should be clean' do
        proxy.dirty?.should be_false
      end
    end

    shared_examples 'dirty? clean_up!' do
      it 'should be dirty' do
        proxy.dirty?.should be_true
      end

      it 'should be clean again after clean_up!' do
        proxy.clean_up!
        proxy.dirty?.should be_false
      end
    end

    context 'when target object has changed directly' do
      before(:each) { proxy << 'baz' }
      include_examples 'dirty? clean_up!'
    end

    context 'when target object has changed in depth' do
      before(:each) { proxy[0] << 'ooo' }
      include_examples 'dirty? clean_up!'
    end
  end
end
