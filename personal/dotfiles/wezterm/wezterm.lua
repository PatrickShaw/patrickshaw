local w = require 'wezterm';
return {
  font = w.font("JetBrains Mono", {
    weight = "Light"
  }),
  check_for_updates = false,
  hide_tab_bar_if_only_one_tab = true,
  enable_scroll_bar = false,
  enable_wayland = true,
  color_scheme   = "followSystem",
  window_padding = {
    left = "5%",
    right = "5%",
    top = 20,
    bottom = 20,
  },
  font_size = 11,
  --color_scheme = "Dracula+",
  colors={
    background='rgba(18,19,17,0.8)',
    scrollbar_thumb = 'rgba(255, 255, 255, 0.01)',
  },
  scrollback_lines = 10000,
  keys={
    { key="LeftArrow", mods="OPT", action=w.action{SendString="\x1bb"} },
    { key="RightArrow", mods="OPT", action=w.action{SendString="\x1bf"} },
  },
  default_cursor_style = "SteadyBar",
  default_prog = { "fish" },
  window_close_confirmation = "NeverPrompt",
  front_end="WebGpu",
};
