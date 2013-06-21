#!/usr/bin/env ruby

require 'pry'
require 'pry-debugger'
require_relative '../htm'
require_relative 'scope'

SCOPE_CONFIG = { panels: [
  { title: :panel1, visible: true, selected: true, instruments: [

    {title: :activity, fg: :red, bg: :blue, type: :basic, visible: true,
     dataf: lambda { |htm| htm.columns }, 
     mapfs: [lambda { |c| c.active? ? '#' : ''}]},

    {title: :rfs, fg: :white, bg: :yellow, type: :basic, visible: true,
     dataf: lambda { |htm| htm.columns }, 
     mapfs: [lambda { |c| c.receptive_field_size.to_i }]}, 

    {title: :overlap, fg: :white, bg: :green, type: :basic, visible: true,
     dataf: lambda { |htm| htm.columns }, 
     mapfs: [lambda { |c| c.overlap.to_i }]}, 

    {title: :boost, fg: :red, bg: :yellow, type: :basic, visible: false,
     dataf: lambda { |htm| htm.columns }, 
     mapfs: [lambda { |c| c.boost }]},

    {title: :inputs, fg: :red, bg: :green, type: :basic, visible: true,
     dataf: lambda { |htm| htm.inputs }, 
     mapfs: [lambda { |c| c.active? ? '#' : '' }]}
    ]}, 
  { title: :panel2, visible: true, selected: false, instruments: [
    {title: :synapses, fg: :green, bg: :yellow, type: :minimal, visible: true,
     dataf: lambda { |htm| htm.columns.map(&:synapses)}, 
     mapfs: [lambda { |s| s.input.index }, 
             lambda { |s| s.active? ? '#' : '' }]} 
  ]}
]}

PATTERN = [[0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1],
           [1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0]] 

Scope.new(HTM.new(pattern: PATTERN), SCOPE_CONFIG).start_scope
