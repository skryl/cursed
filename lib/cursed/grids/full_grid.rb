class Cursed::FullGrid < Cursed::Grid

  CELL_SIZE = 2

  def initialize(container, opts)
    super(container, opts)
    @cell_size = opts[:cell_size] || CELL_SIZE
    @box_size = @cell_size + 2
    @cratio = @box_size
    @rratio = 2
  end

private

  def draw
    full_grid(1, 1)
  end

  #TODO: refactor me
  #
  def full_grid(row,col)
    cells = []
    row_idx_sz = 3

    print_indices(row, col, cell_size+1, rratio)
    rows.times do |r|
      rshift = (rratio - 1) * r
      cols.times do |c|
        cshift = (cratio - 1) * c
        rstart, cstart = row+r+rshift+1, col+c+cshift+row_idx_sz
        cells[r * cols + c] = [rstart+1,cstart+rratio]
        rect(rstart,cstart,rstart+4,cstart+box_size)
      end
    end
    cells
  end

end
