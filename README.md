# Style

This mod provides three libraries that make defining LuaGuiElement style prototypes much, much easier.

> See the wiki for [full documentation](https://github.com/aubergine10/Style/wiki).

## Comparison

Using the API, you can do stuff like this:

```lua
style.path = '__MyMod__/graphics'

style.frame 'example_frame' {
  padding    = {0,6,3,0};
  autoSize   = true;
  background = image.composite 'toolbar.png' { corner = 3 };
  title      = { padding = 0, color = color '#F00' };
  flow       = { padding = 0, spacing = 0, autoSize = true, maxOnRow = 0 };
}
```

Without the API, the above code would look like this (which is actually what the above code does internally):

```lua
data.raw['gui-style'].default['example-frame'] = {
  top_padding = 0,
  right_padding = 6,
  bottom_padding = 3,
  left_padding = 0,
  resize_row_to_width = true,
  resize_to_row_height = true,
  title_top_padding = 0,
  title_right_padding = 0,
  title_bottom_padding = 0,
  title_left_padding = 0,
  font_color = color '#F00',
  graphical_set = {
    type = 'composition',
    filename = '__MyMod__/graphics/toolbar.png',
    position = { 0, 0 },
    corner = { 3, 3 },
    priority = 'extra-high-no-scale',
  },
  flow_style = {
    top_padding = 0,
    right_padding = 0,
    bottom_padding = 0,
    left_padding = 0,
    horizontal_spacing = 0,
    vertical_spacing = 0,
    resize_row_to_width = true,
    resize_to_row_height = true,
    max_on_row = 0,
  }
}
```

See the difference?
