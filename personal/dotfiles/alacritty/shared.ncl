fun system => {
  font = {
    normal = {
      family = "JetBrains Mono",
    },
    size = 11,
  },
  cursor = {
    style = "Beam",
  },
  selection = {
    semantic_escape_chars = ",│`|:=\"' ()[]{}<>-",
  },
  scrolling = {
    history = 40000,
    multiplier = 1,
    faux_multiplier = 1,
    auto_scroll = true,
  },
  colors = {
    primary = {
      background = "0x1e1e1e",
      foreground = "0xffffff",
    },
    normal = {
      black =      "0x171421",
      red =        "0xc01c28",
      green =      "0x26a269",
      yellow =     "0xa2734c",
      blue =       "0x12488b",
      magenta =    "0xa347ba",
      cyan =       "0x2aa1b3",
      white =      "0xd0cfcc",
    },
    # Bright colors
    bright = {
      black = "0x535c64",
      red =        "0xf66151",
      green =      "0x33d17a",
      yellow =     "0xe9ad0c",
      blue =       "0x2a7bde",
      magenta =    "0xc061cb",
      cyan =       "0x33c7de",
      white =      "0xffffff",
    },
  },
  window = {
    opacity = if system == "linux" then 0.9 else 1
  }
}