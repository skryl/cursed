require_relative 'grid'

class MinimalGrid < Grid

  def initialize(window, **opts)
    super(window, opts)
    @cratio, @rratio, @cell_size = 3, 1, 2
  end

private

  def draw
    quick_minimal_grid
  end

  def quick_minimal_grid
    minimal_grid(0, 0, rows, cols-1, @cell_size)
  end

end
