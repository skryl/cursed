require_relative 'grid'

class FullGrid < Grid

  def initialize(window, **opts)
    super(window, opts)
    @cratio, @rratio, @cell_size = 4, 2, 4
  end

private

  def draw
    quick_grid
  end

  def quick_grid
    grid(0, 0, rows-1, cols, @cell_size)
  end

end
