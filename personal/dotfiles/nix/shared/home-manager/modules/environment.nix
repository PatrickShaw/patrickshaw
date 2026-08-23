# Session variables and shell aliases.
#
# These used to be `environment.variables` / `environment.shellAliases`, i.e.
# imposed on every account on the machine. They're personal preferences, so
# they belong to the user instead.
{ ... }: {
  home.sessionVariables = {
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

  # Home Manager writes these into both the zsh and fish config it generates,
  # which also removes the need for the nix-darwin /etc/zshrc workaround that
  # used to live in shared/configuration.nix.
  home.shellAliases = import ./program-aliases.nix { };
}
