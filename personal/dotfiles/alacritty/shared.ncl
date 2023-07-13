fun system => {
  "import" = [
    "~/personal/dotfiles/alacritty/theme.yml",
  ],
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
  window = {
    opacity = if system == "linux" then 0.95 else 1,
    padding = {
      x = 12,
      y = 12,
    },
  }
}