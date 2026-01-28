# Common configuration shared between Darwin and NixOS
{ ... }:
{
  # This module contains configuration that applies to both platforms
  # Currently most shared config is in home-manager modules

  # Add any shared system-level configuration here
  # For example, common nix settings:
  # nix.settings = {
  #   auto-optimise-store = true;
  #   experimental-features = [ "nix-command" "flakes" ];
  # };
}
