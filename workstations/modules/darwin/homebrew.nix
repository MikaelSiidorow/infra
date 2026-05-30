# Homebrew configuration for macOS
{ ... }:
{
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

    brews = [
      "cloudflared"
      "render"
    ];

    casks = [
      "orbstack"
      "ghostty"
      "cmux"
      "google-chrome"
      "1password"
      "raycast"
      "slack"
      "microsoft-auto-update" # needed for teams I guess?
      "microsoft-teams"
      "drata-agent"
      "obs"
    ];
  };
}
