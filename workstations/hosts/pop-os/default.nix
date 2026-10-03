# Pop!_OS host configuration for home-manager standalone
{ pkgs, ... }:
let
  tailscale-headscale-setup = pkgs.writeShellApplication {
    name = "tailscale-headscale-setup";
    runtimeInputs = [ pkgs.jq ];
    text = builtins.readFile ./tailscale-headscale-setup.sh;
  };
in
{
  # This is a minimal configuration for running home-manager standalone on Pop!_OS
  # We're not managing the system itself, just the user environment

  # Allow unfree packages (needed for Discord, Steam, etc.)
  nixpkgs.config.allowUnfree = true;

  # Integrate this non-NixOS host with Home Manager, including native GPU
  # drivers exposed through /run/opengl-driver.
  targets.genericLinux.enable = true;

  # Pop!_OS owns the privileged tailscaled service. Keep using its matching
  # system CLI and expose an idempotent command for applying our client prefs.
  home.packages = [ tailscale-headscale-setup ];
}
