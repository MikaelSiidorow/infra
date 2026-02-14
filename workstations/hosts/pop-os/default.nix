# Pop!_OS host configuration for home-manager standalone
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  # This is a minimal configuration for running home-manager standalone on Pop!_OS
  # We're not managing the system itself, just the user environment

  # Allow unfree packages (needed for Discord, Steam, etc.)
  nixpkgs.config.allowUnfree = true;

  # nixGL for OpenGL support on non-NixOS Linux
  # Wraps Nix GUI apps to use system graphics drivers
  targets.genericLinux.nixGL.packages = inputs.nixgl.packages;
  targets.genericLinux.nixGL.defaultWrapper = "mesa";
  targets.genericLinux.nixGL.installScripts = [ "mesa" ];
}
