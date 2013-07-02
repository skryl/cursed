module GridPrimitives

  BAR = "|"
  PLS = "+"
  MNS = "-"

  def rect(row1,col1,row2,col2)
    width = col2 - col1 + 1
    height = (row2 - row1)/2

    write(row1, col1, PLS )
    write(row1, col2, PLS )
    write(row1, col1+1, (MNS * (width-2)) )
    (1..height).each do |i| 
      write(row1 + i, col1, BAR)
      write(row1 + i, col2, BAR)
    end
    write(row1 + height, col1, PLS )
    write(row1 + height, col2, PLS )
    write(row1 + height, col1+1, (MNS * (width-2)) )
  end

  def sqr(row,col,side)
    rect(row,col,row+side,col+side)
  end

  def grid(row,col,rows,cols,size)
    cells = []
    rows.times do |r|
      rshift = (size/2 - 1) * r
      cols.times do |c|
        cshift = (size-1) * c
        rstart, cstart = row+r+rshift, col+c+cshift
        cells[r * cols + c] = [rstart+1,cstart+size/2]
        sqr(rstart,cstart,size)
      end
    end
    cells
  end

  def minimal_grid(row,col,rows,cols,size,vscroll,hscroll)
    cells = []
    hscroll, vscroll = hscroll, vscroll

    idx_div = ' ' * (size/2)
    idx_size = idx_div.size+2
    cell_div = ' ' * size
    cell = '+' + cell_div
    cell_size = cell.size

    # print top indices
    col_indices = (hscroll...hscroll+cols).map{|i| format_val(i)}.join(idx_div)
    write(row, col, cell_div + cell_div + col_indices)

    # print side indices
    row_indices = (vscroll...vscroll+rows).map{|i| format_val(i)}
    row_indices.each.with_index { |ridx, i| write(row+1+i, col, ridx) }

    # print cells
    rows.times do |r|
      cols.times do |c|
        rpos, cpos = row+r+1, idx_size+col+c*cell_size
        write(rpos, cpos, cell)
        cells[r * cols + c] = [rpos, cpos+1]
      end
    end
    cells
  end

end
