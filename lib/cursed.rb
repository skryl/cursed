require 'curses'
require 'forwardable'
require 'cursed/version'
require 'cursed/window'

require 'cursed/core/object.rb'
require 'cursed/core/class.rb'
require 'cursed/core/hash.rb'
require 'cursed/core/try.rb'

module Cursed
  autoload :Buffer,      'cursed/buffer'
  autoload :Container,   'cursed/container'
  autoload :FullGrid,    'cursed/elements/full_grid'
  autoload :Grid,        'cursed/grid'
  autoload :Instrument,  'cursed/elements/instrument'
  autoload :MinimalGrid, 'cursed/elements/minimal_grid'
  autoload :Scope,       'cursed/scope'
  autoload :Utils,       'cursed/utils'
  autoload :WM,          'cursed/wm'
end
