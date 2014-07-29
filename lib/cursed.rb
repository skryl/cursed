require 'curses'
require 'forwardable'
require 'cursed/version'
require 'cursed/window'

module Cursed
  autoload :Body,        'cursed/containers/body'
  autoload :Buffer,      'cursed/buffer'
  autoload :Container,   'cursed/container'
  autoload :FullGrid,    'cursed/grids/full_grid'
  autoload :Grid,        'cursed/grid'
  autoload :Header,      'cursed/containers/header'
  autoload :Instrument,  'cursed/containers/instrument'
  autoload :Menu,        'cursed/containers/menu'
  autoload :MinimalGrid, 'cursed/grids/minimal_grid'
  autoload :Panel,       'cursed/containers/panel'
  autoload :Screen,      'cursed/containers/screen'
  autoload :WM,          'cursed/wm'
end
