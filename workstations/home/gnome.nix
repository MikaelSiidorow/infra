# GNOME desktop settings for Linux
{ lib, ... }:
{
  dconf.settings = {
    # Interface: clock, theme, fonts
    "org/gnome/desktop/interface" = {
      clock-format = "24h";
      color-scheme = "prefer-dark";
      show-battery-percentage = true;
      font-name = "Inter 11";
      monospace-font-name = "Roboto Mono 11";
    };

    # Keyboard layouts: Finnish + Pinyin
    "org/gnome/desktop/input-sources" = {
      sources = [
        (lib.gvariant.mkTuple [
          "xkb"
          "fi+classic"
        ])
        (lib.gvariant.mkTuple [
          "ibus"
          "libpinyin"
        ])
      ];
      per-window = false;
    };

    # Mouse
    "org/gnome/desktop/peripherals/mouse" = {
      natural-scroll = false;
    };

    # Touchpad
    "org/gnome/desktop/peripherals/touchpad" = {
      natural-scroll = true;
      two-finger-scrolling-enabled = true;
      disable-while-typing = false;
    };

    # Privacy
    "org/gnome/desktop/privacy" = {
      recent-files-max-age = 30;
      remove-old-temp-files = true;
      remove-old-trash-files = true;
    };

    # Session: 8min idle
    "org/gnome/desktop/session" = {
      idle-delay = lib.gvariant.mkUint32 480;
    };

    # Power: 30min sleep on AC and battery
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-timeout = 1800;
      sleep-inactive-battery-timeout = 1800;
    };

    # Nautilus: list view by default
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
    };

    # Dock: pinned apps and autohide (similar to macOS config)
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "io.elementary.appcenter.desktop"
        "com.google.Chrome.desktop"
        "com.mitchellh.ghostty.desktop"
        "code.desktop"
        "vesktop.desktop"
        "org.telegram.desktop.desktop"
      ];
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-fixed = false;
      autohide = true;
      intellihide = false;
      extend-height = false;
      show-trash = false;
      show-mounts = false;
      dash-max-icon-size = 48;
      show-show-apps-button = true;
    };

    # Disable GNOME's built-in screenshot UI
    "org/gnome/shell/keybindings" = {
      show-screenshot-ui = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
    };

    # Custom keybindings and disable default terminal
    "org/gnome/settings-daemon/plugins/media-keys" = {
      terminal = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
    };

    # Ghostty keybinding: Super+T
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Ghostty";
      command = "ghostty";
      binding = "<Super>t";
    };

    # Flameshot screenshot: Print Screen
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "Flameshot";
      command = "flameshot gui";
      binding = "Print";
    };
  };
}
