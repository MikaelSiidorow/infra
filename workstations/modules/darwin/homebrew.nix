# Homebrew configuration for macOS
{ ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      # cleanup = "zap";
      upgrade = true;
    };

    global = {
      brewfile = true;
    };

    brews = [
      "cloudflared"
      "render"
    ];

    casks = [
      "firefox"
      "orbstack"
      "ghostty"
      "cmux"
      "google-chrome"
      "1password"
      "amethyst"
      "alfred"
      "slack"
      "microsoft-auto-update" # needed for teams I guess?
      "microsoft-teams"
      "drata-agent"
      "obs"
    ];
  };
}
