# Cursed

Cursed is a curses based window manager for displaying large amounts of tabular data.

## Screenshots

<img src="https://dl.dropbox.com/s/wgruhghr9cxqcm4/cursed_anim.gif " alt="Animation" style="width: 600px;"/>

## Installation

Add this line to your application's Gemfile:

    gem 'cursed'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cursed

## Default Keybindings

```
# Normal Mode
h   - left
j   - down
k   - up
l   - right
H   - scroll left
J   - scroll down
K   - scroll up
L   - scroll right
D   - scroll down 10
U   - scroll up 10
x   - hide instrument
X   - hide panel
m   - show menu
n   - next screen
p   - prev screen
[s] - step simulation
f   - step simulation 10 times
F   - step simulation 100 times
b   - break
q   - exit

# Menu Mode
m        - hide menu
(0-9)    - show instrument (0-9)
^(0-9) - show panel (0-9)

# Legend
[s] - spacebar
^   - shift
```

## Usage

Cursed uses a config hash to setup the layout, custom keybindings, and header info, as
well as to interface with an external data source.

```ruby
CURSED_CONFIG = { 

  keybindings: {
    32.chr => -> { step },
    'f'    => -> { step(10) },
    'F'    => -> { step(100) }
  },

  header: {
    status: {
      mode:       -> { mode.upcase },
      screen:     -> { active_screen.title },
      cycles:     -> { data_obj.cycles },
      step_time:  -> { step_time.round(2) },
      inputs:     -> { data_obj.num_inputs },
      columns:    -> { data_obj.num_columns },
      cells:      -> { data_obj.num_cells} },

    columns: {
      input_size:      Column::INPUT_SIZE,
      min_overlap:     ProximalDendrite::MIN_OVERLAP,
      iradius:         -> { data_obj.inhibition_radius },
      des_local_act:   -> { Column::DESIRED_LOCAL_ACTIVITY },
      active_columns:  -> { data_obj.active_columns.count },
      col_act_ratio:   -> { data_obj.column_activity_ratio } },

    cells: {
      learning_cells:   -> { data_obj.learning_cells.count },
      predicted_cells:  -> { data_obj.predicted_cells.count },
      active_cells:     -> { data_obj.active_cells.count },
      cell_act_ratio:   -> { data_obj.cell_activity_ratio } }
  },

  screens: [
    { title: 1, panels: [
      { title: :activity, visible: true, instruments: [

        {title: :activity, fg: :red, bg: :blue, type: :full, visible: true,
         dataf:    lambda { |htm| htm.columns }, 
         streamfs: [lambda { |c| c.active? ? '#' : ''}]},

        {title: :inputs, fg: :red, bg: :green, type: :full, visible: true,
         dataf:    lambda { |htm| htm.inputs }, 
         streamfs: [lambda { |c| c.active? ? '#' : '' }]}
      ]},
      { title: :overlap, visible: true, instruments: [

        {title: :overlap, fg: :green, bg: :yellow, type: :full, cell_size: 5, visible: true,
         dataf:    lambda { |htm| htm.columns }, 
         streamfs: [lambda { |c| c.overlap }]}, 

        {title: :min_local_activity, fg: :blue, bg: :green, type: :full, cell_size: 5, visible: true,
         dataf:    lambda { |htm| htm.columns },
         streamfs: [lambda { |c| c.min_local_activity }]}
      ]}
    ]}
]}
```

The data source and config hash are provided during initialization.

```ruby
Cursed::WM.new(HTM.new(pattern: PATTERN), CURSED_CONFIG).start
```

## Contributing

This release is very very beta. There are bugs. There are no tests. Stuff may
break. If you have an idea for how to fix it, follow directions below...

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
