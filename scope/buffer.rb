class Buffer
  extend Forwardable
  def_delegator :@window, :effective_height, :height
  def_delegator :@window, :effective_width, :width

  def initialize(window)
    @window = window
    @content = ''
  end

  def puts(str)
    @content << str
  end

  alias_method :<<, :puts

  def slices
    @content.scan(/.{1,#{width}}/)[0...height]
  end

  def to_s
    @content[0..height * width]
  end

  def flush
    to_s
    clear!
  end

  def clear!
    @content = ''
  end

end
