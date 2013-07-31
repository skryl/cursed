require_relative 'grid'

class Cursed::MinimalGrid < Cursed::Grid

  CELL_SIZE = 2
  
  def initialize(window, **opts)
    super(window, opts)
    @cell_size = opts[:cell_size] || CELL_SIZE
    @box_size = @cell_size + 1
    @cratio = @box_size
    @rratio = 1
    @scroll_amt = 3
  end

private

  def draw
    minimal_grid(1, 1)
  end

  #TODO: refactor me
  #
  def minimal_grid(row,col)
    cells = []
    hscroll, vscroll = hscroll, vscroll

    cell = '+' + ' ' * cell_size
    row_idx_sz = 3

    print_indices(row, col, cell_size, rratio)
    rows.times do |r|
      cols.times do |c|
        rpos, cpos = row+r+1, row_idx_sz+col+c*box_size
        write(rpos, cpos, cell)
        cells[r * cols + c] = [rpos, cpos+1]
      end
    end
    cells
  end

end
