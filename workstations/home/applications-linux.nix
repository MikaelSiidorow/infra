# Linux-specific desktop applications
{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    # Communication
    discord
    # telegram-desktop - using flatpak instead due to graphics driver issues

    # Gaming
    # steam - using apt version instead (better 32-bit lib support on Pop!_OS)

    # Productivity
    obsidian

    # Terminal with nixGL wrapping (uses config.lib.nixGL.wrap)
    (config.lib.nixGL.wrap ghostty)
  ];
}
