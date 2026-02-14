# GNOME desktop settings for Linux
{ lib, ... }:
{
  dconf.settings = {
    # Custom keybindings and disable default terminal
    "org/gnome/settings-daemon/plugins/media-keys" = {
      terminal = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };

    # Ghostty keybinding: Super+T
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Ghostty";
      command = "ghostty";
      binding = "<Super>t";
    };
  };
}
