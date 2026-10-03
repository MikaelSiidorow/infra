# User-level Nix client configuration.
{ config, ... }:
{
  sops.templates."nix-access-tokens.conf".content = ''
    access-tokens = github.com=${config.sops.placeholder."github/token"}
  '';

  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
    !include ${config.sops.templates."nix-access-tokens.conf".path}
  '';
}
