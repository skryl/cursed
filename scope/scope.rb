require_relative 'window'
require_relative 'panel'

class Scope < Window

  HEADER_HEIGHT = 4
  FOOTER_HEIGHT = 4

  attr_reader :htm

  def initialize(htm, config)
    @mode = :normal
    super(window: Curses.stdscr, border: false)
    @htm = htm

    @header = Window.new(parent: self, title: :status, border: true, height: HEADER_HEIGHT)
    @body   = Window.new(parent: self, title: :body, border: false, flow: :horizontal) 
    @panels = config[:panels].map { |config| 
      Panel.new(config, parent: @body, border: false, top: @header.top + @header.height, 
        height: self.effective_height - @header.height) }
    @footer = Window.new(parent: self, title: :menu, border: true, visible: false,
        height: FOOTER_HEIGHT, top: self.top + self.height - FOOTER_HEIGHT)

    @left_panel  = visible_panels[0]
    @right_panel = visible_panels[1]
    @left_panel.select unless @right_panel.selected?
    start_scope
  end

  def start_scope
    @cwindow.init_display do
      refresh!
      loop do 
        Curses.getch.tap do |input| 
          react_to_input(input) if input 
        end
      end
    end
  end

  def react_to_input(input)
    case @mode
    when :normal
      case input
      when ?k then change_selected(:up)
      when ?j then change_selected(:down)
      when ?l then change_selected(:right)
      when ?h then change_selected(:left)
      when ?x then hide_selected_instrument
      when ?X then hide_selected_panel
      when ?s then switch_mode(:show)
      when ?K then scroll_instrument(:up)
      when ?J then scroll_instrument(:down)
      when ?L then scroll_instrument(:right)
      when ?H then scroll_instrument(:left)
      when ?q then exit
      when ?n then step
      when ?N then step(10)
      when ?f then step(100)
      end
    when :show
      case input
      when ?s then switch_mode(:normal)
      when ?0 then show_instrument(0)
      when ?1 then show_instrument(1)
      when ?2 then show_instrument(2)
      when ?3 then show_instrument(3)
      when ?4 then show_instrument(4)
      when ?5 then show_instrument(5)
      when ?6 then show_instrument(6)
      when ?7 then show_instrument(7)
      when ?8 then show_instrument(8)
      when ?9 then show_instrument(9)
      when ?) then show_panel(0)
      when ?! then show_panel(1)
      when ?@ then show_panel(2)
      when ?# then show_panel(3)
      when ?$ then show_panel(4)
      when ?% then show_panel(5)
      when ?^ then show_panel(6)
      when ?& then show_panel(7)
      when ?* then show_panel(8)
      when ?( then show_panel(9)
      when ?q then exit
      end
    end
    refresh!
  end

  def refresh
    @header << header_content
    @footer << menu_content
    super
  end

# modes

  def switch_mode(mode)
    case mode
    when :show
      @footer.show
    when :normal
      @footer.hide
    end
    @mode = mode 
  end

  def normal_mode?; @mode == :normal end
  def show_mode?; @mode == :show end

# header / footer
  
  def header_content
    <<-eos
mode: #{@mode.upcase}  learning: #{@htm.learning}  columns: #{@htm.num_columns}  inputs: #{@htm.num_inputs}  input_size: #{Column::INPUT_SIZE}  min_overlap: #{Column::MIN_OVERLAP}  desired_local_activity: #{Column::DESIRED_LOCAL_ACTIVITY}
cycles: #{@htm.cycles}  ir: #{@htm.inhibition_radius}  activity_ratio: #{@htm.activity_ratio}
    eos
  end

  def menu_content
    case @mode
    when :normal
      ''
    when :show
      %Q(PANELS: #{hidden_child_index(@body)} INSTRUMENTS: #{hidden_child_index(active_panel)})
    end
  end

  def hidden_child_index(window)
    window.hidden_children.map.with_index{ |c,i| "[#{i}](#{c.title})" }.join(' ')
  end

# panels

  def change_selected(direction)
    case direction
    when :up
      active_panel.select_adjacent_child(:prev)
    when :down
      active_panel.select_adjacent_child(:next)
    when :right
      @body.select_adjacent_child(:next)
    when :left
      @body.select_adjacent_child(:prev)
    end
  end

  def visible_panels
    @body.visible_children
  end

  def active_panel
    @body.active_child
  end

  def active_instrument
    active_panel.active_child
  end

  def hide_selected_instrument
    active_panel.hide_selected
  end

  def hide_selected_panel
    @body.hide_selected
  end

  def show_instrument(num)
    ins = active_panel.hidden_children[num]
    ins && ins.show
    switch_mode(:normal)
  end

  def show_panel(num)
    pan = @body.hidden_children[num]
    pan && pan.show
    switch_mode(:normal)
  end

  def scroll_instrument(direction)
    active_instrument.scroll(direction)
  end

# simulation

  def step(n=1)
    n.times { @htm.step }
  end

end
