class Cursed::Buffer
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

  # properly justify fields passed in as:
  #   [[Row, [[Field, Val], ...]], ...]
  #
  def format_fields(attributes)
    maxlen = attributes.flat_map { |(row, fields)| fields }.
                          map { |field| field.join.length }.
                          max

    @content = attributes.inject('') do |str, (row, fields)|
      str << "#{row.to_s.upcase}:".ljust(10)
      fields.map { |name, val| str << "#{name}: #{val}".ljust(maxlen+2) << ' ' } 
      str << "\n"
    end
  end

end
