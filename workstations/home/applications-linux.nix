# Linux-specific desktop applications
{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    # Communication
    vesktop
    # telegram-desktop - using flatpak instead due to graphics driver issues

    # Gaming
    # steam - using apt version; wrapper below strips Nix PATH to avoid glibc conflicts

    # Productivity
    obsidian

    # Cloud
    azure-cli
    stripe-cli

    # Document processing
    texliveFull

    # Screenshot
    flameshot

    # Terminal with nixGL wrapping (uses config.lib.nixGL.wrap)
    (config.lib.nixGL.wrap ghostty)
  ];

  # Wrap apt Steam to use system PATH (Nix coreutils link to newer glibc than Pop!_OS ships)
  xdg.desktopEntries.steam = {
    name = "Steam";
    comment = "Application for managing and playing games on Steam";
    exec = ''env PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games" LD_LIBRARY_PATH="" /usr/games/steam %U'';
    icon = "steam";
    terminal = false;
    type = "Application";
    categories = [ "Game" "Network" ];
    mimeType = [ "x-scheme-handler/steam" "x-scheme-handler/steamlink" ];
  };

  programs.zed-editor = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.zed-editor;
  };
}
