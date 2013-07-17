require_relative './spec_helper'
require_relative '../common/temporal_attributes'

describe TemporalAttributes do

  let(:history) { class History; include TemporalAttributes end }
  let(:h) { history.new }
  let(:h2) { history.new }

  it 'class should respond to class methods' do
    history.should respond_to(:temporal_attr)
    history.should respond_to(:temporal_attributes)
    history.should respond_to(:temporal_attribute_settings)
  end

  it 'object should respond to instance methods' do
    h.should respond_to(:global_time)
    h.should respond_to(:use_global_time)
    h.should respond_to(:temporal_attributes)
    h.should respond_to(:temporal_attribute_settings)
    h.should_not respond_to(:set_global_time)
  end

  it 'should add a temporal attribute' do
    history.temporal_attr(:a)
    history.temporal_attr(:b, history: 3)
    history.temporal_attr(:c, :d, history: 4)
    history.temporal_attributes.should == [:a, :b, :c, :d]
    history.temporal_attribute_settings.should == { a: 2, b: 3, c: 4, d: 4 }
    h.should respond_to(:a, :b, :c, :d)
  end

  it 'should get/set a temporal attribute' do
    history.temporal_attr :a, history: 3  
    h.set(:a, 1)
    h.set(:a, 2)
    h.set(:a, 3)
    h.a = 4
    h.a.should == 4
    h.a(1).should == 3
    h.get(:a, 2).should == 2
    h.get(:a, 3).should == nil
  end

  it 'should return historical value when global time is changed' do
    history.temporal_attr :a, history: 3  
    history.temporal_attr :b, history: 4 

    h.global_time.should == 0
    h2.global_time.should == 0

    (1..5).each { |t| h.a = t; h2.b = t+1 }
    h.use_global_time(0) { [h.a, h2.b] }.should == [5, 6]
    h.use_global_time(1) { [h.a, h2.b] }.should == [4, 5]
    h.use_global_time(2) { [h.a, h2.b] }.should == [3, 4]
    h.use_global_time(3) { [h.a, h2.b] }.should == [nil, 3]
    h.use_global_time(4) { [h.a, h2.b] }.should == [nil, nil]
  end
  
end
