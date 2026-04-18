# macOS system defaults
{
  pkgs,
  username,
  inputs,
  ...
}:
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
          app = "/Applications/cmux.app";
        }
        {
          app = "${pkgs.vscode}/Applications/Visual Studio Code.app";
        }
        {
          app = "${
            inputs.t3code.packages.${pkgs.stdenv.hostPlatform.system}.default
          }/Applications/T3 Code (Alpha).app";
        }
        {
          app = "/Applications/Firefox.app";
        }
      ];
    };
    # Use CustomUserPreferences for persistent-others so we can set view
    # options. The typed `dock.persistent-others` only accepts paths.
    # arrangement: 1=name 2=date-added 3=date-modified 4=date-created 5=kind
    # displayas:   0=stack 1=folder
    # showas:      0=auto 1=fan 2=grid 3=list
    CustomUserPreferences."com.apple.dock".persistent-others = [
      {
        tile-type = "directory-tile";
        tile-data = {
          file-label = "Downloads";
          file-type = 2;
          arrangement = 2;
          displayas = 0;
          showas = 1;
          file-data = {
            _CFURLString = "file:///Users/${username}/Downloads/";
            _CFURLStringType = 15;
          };
        };
      }
    ];
  };
}
