# Pop!_OS host configuration for home-manager standalone
_: {
  # This is a minimal configuration for running home-manager standalone on Pop!_OS
  # We're not managing the system itself, just the user environment

  # Allow unfree packages (needed for Discord, Steam, etc.)
  nixpkgs.config.allowUnfree = true;

  # Integrate this non-NixOS host with Home Manager, including native GPU
  # drivers exposed through /run/opengl-driver.
  targets.genericLinux.enable = true;
}
