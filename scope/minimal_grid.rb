require_relative 'grid'

class MinimalGrid < Grid

  def initialize(window, **opts)
    super(window, opts)
    @cratio, @rratio, @cell_size = 3, 1, 2
  end

private

  def draw
    minimal_grid(1, 1, @rows, @cols, @cell_size, @vscroll, @hscroll)
  end

end
