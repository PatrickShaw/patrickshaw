# Session variables and shell aliases.
#
# These used to be `environment.variables` / `environment.shellAliases`, i.e.
# imposed on every account on the machine. They're personal preferences, so
# they belong to the user instead.
{ ... }: {
  home.sessionVariables = {
    # LLM: npm's default global prefix is its own (read-only) Nix store path - 
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    # Starship's default is ~/.config/starship.toml; dotfiles.nix links the
    # whole directory instead.
    STARSHIP_CONFIG = "$HOME/.config/starship/starship.toml";
    VISUAL = "nvim";
    TERMINAL = "ghostty";
    BROWSER = "firefox";

    # No mkOverride needed here: as a user session variable this no longer
    # competes with nix-darwin's system-level `mkDefault "nano"`.
    EDITOR = "nvim";
    PAGER = "cat";

    # We don't use MCFLY but leaving this here cause harmless
    # See https://github.com/cantino/mcfly#fuzzy-searchingo.
    MCFLY_FUZZY = "2";
    MCFLY_HISTORY_LIMIT = "40000";
    MCFLY_PROMPT = "❯";
    MCFLY_RESULTS = "15";
  };

  # Declared here rather than per shell so zsh and fish can't drift apart.
  # Prepended to PATH in list order, so earlier entries win.
  home.sessionPath = [
    # XDG's user executable dir; claude, rovo, pipx and uv install here.
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
    "$HOME/.cargo/bin"
  ];

  # Home Manager writes these into both the zsh and fish config it generates,
  # which also removes the need for the nix-darwin /etc/zshrc workaround that
  # used to live in shared/configuration.nix.
  home.shellAliases = import ./program-aliases.nix { };
}
