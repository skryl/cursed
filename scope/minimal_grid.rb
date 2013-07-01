require_relative 'grid'

class MinimalGrid < Grid

  def initialize(window, **opts)
    super(window, opts)
    @cratio, @rratio, @cell_size = 3, 1, 2
  end

private

  def draw(**opts)
    quick_minimal_grid(opts)
  end

  def quick_minimal_grid(**opts)
    minimal_grid(1, 1, rows-1, cols-1, @cell_size, opts[:vscroll], opts[:hscroll])
  end

end
