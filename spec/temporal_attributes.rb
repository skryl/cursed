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
    history.temporal_attr(:b, type: :historical, history: 3)
    history.temporal_attr(:c, :d, type: :snapshot, history: 4)
    history.temporal_attributes.should == [:a, :b, :c, :d]
    history.temporal_attribute_settings.should == { a: [:historical, 2], b: [:historical, 3], 
                                                    c: [:snapshot, 4], d: [:snapshot, 4] }
    h.should respond_to(:a, :b, :c, :d)
  end

  it 'should get/set a historical attribute' do
    history.temporal_attr :a, type: :historical, history: 3  
    h.set(:a, 1)
    h.set(:a, 2)
    h.set(:a, 3)
    h.a = 4
    h.a.should == 4
    h.a(1).should == 3
    h.get(:a, 2).should == 2
    h.get(:a, 3).should == nil
  end

  it 'should get/set a snapshot attribute' do
    history.temporal_attr :a, type: :snapshot, history: 3  
    h.set(:a, 1)
    h.set(:a, 2)
    h.get(:a, 1).should == nil
    h.snap
    h.a.should == 2
    h.a(1).should == 2
    h.a = 4
    h.a = 5
    h.a.should == 5
    h.a(1).should == 2
    h.get(:a, 2).should == nil
  end

  it 'should return historical value when global time is changed' do
    history.temporal_attr :a, type: :historical, history: 3  
    history.temporal_attr :b, type: :snapshot,   history: 3 
    history.temporal_attr :c, type: :historical, history: 4  
    history.temporal_attr :d, type: :snapshot,   history: 4 

    # test two instances to confirm global time change
    h.global_time.should == 0
    h2.global_time.should == 0

    (1..5).each { |t| h.a, h2.c = t, t+1 }
    (1..5).each { |t| h.b, h2.d = t, t+1; (h.snap; h2.snap) if t < 5 }

    h.use_global_time(0) { [h.a, h.b, h2.c, h2.d] }.should == [5, 5, 6, 6]
    h.use_global_time(1) { [h.a, h.b, h2.c, h2.d] }.should == [4, 4, 5, 5]
    h.use_global_time(2) { [h.a, h.b, h2.c, h2.d] }.should == [3, 3, 4, 4]
    h.use_global_time(3) { [h.a, h.b, h2.c, h2.d] }.should == [nil, nil, 3, 3]
    h.use_global_time(4) { [h.a, h.b, h2.c, h2.d] }.should == [nil, nil, nil, nil]
  end
  
end
