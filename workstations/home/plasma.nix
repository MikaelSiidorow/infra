# Minimal KDE preferences; Plasma owns everything not listed here.
{
  programs.plasma = {
    enable = true;

    workspace.lookAndFeel = "org.kde.breezedark.desktop";

    input.keyboard.layouts = [ { layout = "fi"; } ];

    # Let KWin launch Fcitx through its native Wayland input-method protocol.
    configFile.kwinrc.Wayland.InputMethod = "/run/current-system/sw/share/applications/org.fcitx.Fcitx5.desktop";

    # ponytail: reuse Plasma's standard widgets and behavior.
    panels = [
      {
        location = "top";
        floating = true;
      }
    ];

    hotkeys.commands.vicinae = {
      name = "Vicinae";
      key = "Meta+Space";
      command = "vicinae toggle";
    };
  };
}
