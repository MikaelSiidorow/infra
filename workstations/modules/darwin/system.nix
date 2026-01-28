# macOS system defaults
{ pkgs, username, ... }:
{
  system.defaults = {
    NSGlobalDomain.AppleICUForce24HourTime = true;
    menuExtraClock.ShowSeconds = true;
    dock = {
      launchanim = false;
      tilesize = 48;
      autohide = true;
      show-recents = false;
      orientation = "bottom";
      persistent-apps = [
        {
          app = "/System/Library/CoreServices/Finder.app";
        }
        {
          app = "/System/Applications/Notes.app";
        }
        {
          app = "/System/Applications/System Settings.app";
        }
        {
          app = "/Applications/Slack.app";
        }
        {
          app = "/Applications/1Password.app";
        }
        {
          app = "/Applications/Google Chrome.app";
        }
        {
          app = "/Applications/Ghostty.app";
        }
        {
          app = "${pkgs.vscode}/Applications/Visual Studio Code.app";
        }
        {
          app = "/Applications/Firefox.app";
        }
      ];
      persistent-others = [
        "/Users/${username}/Downloads"
      ];
    };
  };
}
