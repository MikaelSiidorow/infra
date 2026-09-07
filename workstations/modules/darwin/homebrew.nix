# Homebrew configuration for macOS
_: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      # cleanup = "zap";
      upgrade = false;
    };

    global = {
      brewfile = true;
    };

    # Chrome, 1Password, Teams and drata-agent come from the enterprise MDM.
    casks = [
      "ghostty"
      "cmux"
      "raycast"
    ];
  };
}
