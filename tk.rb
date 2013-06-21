require 'tk'

root = TkRoot.new

@canvas = TkCanvas.new(root) do
  place('height' => 200, 'width' => 200, 'x' => 10, 'y' => 10)
end

@canvas.grid :sticky => 'nwes', :column => 0, :row => 0
TkGrid.columnconfigure(root, 0, :weight => 1)
TkGrid.rowconfigure(root, 0, :weight => 1)

@lastx = 0
@lasty = 0

@canvas.bind("1", proc { |x,y| @lastx = x; @lasty = y }, "%x %y")
@canvas.bind("B1-Motion", proc { |x,y| addLine(x,y) }, "%x %y")

def addLine(x,y)
  TkcLine.new(@canvas, @lastx, @lasty, x, y)
  @lastx = x; @lasty = y
end

def addRectangle(x1,y1,x2,y2)
  TkcRectangle.new(@canvas, x1, y1, x2, y2, 'width' => 1)
end

addRectangle(10,5,55,50)

# TkButton.new(@canvas) {
#   text "Step"
#   command proc { addRectangle(10,5,55,50) }
#   pack('side' => 'left', 'padx' => 10, 'pady' => 10)
# }


Tk.mainloop
