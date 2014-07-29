require 'curses'
require 'forwardable'
require 'cursed/version'
require 'cursed/curses_window'

module Cursed
  autoload :Body,        'cursed/body'
  autoload :Buffer,      'cursed/buffer'
  autoload :FullGrid,    'cursed/full_grid'
  autoload :Grid,        'cursed/grid'
  autoload :Header,      'cursed/header'
  autoload :Instrument,  'cursed/instrument'
  autoload :Menu,        'cursed/menu'
  autoload :MinimalGrid, 'cursed/minimal_grid'
  autoload :Panel,       'cursed/panel'
  autoload :Screen,      'cursed/screen'
  autoload :WM,          'cursed/wm'
  autoload :Window,      'cursed/window'
end
