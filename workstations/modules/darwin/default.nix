# Darwin (macOS) specific modules
{
  self,
  pkgs,
  username,
  ...
}:
{
  imports = [
    (import ./system.nix { inherit pkgs username; })
    ./homebrew.nix
  ];

  environment.systemPackages = [
    pkgs.vim
  ];

  services.skhd.enable = true;

  nix.settings.experimental-features = "nix-command flakes";

  nixpkgs.config.allowUnfree = true;

  programs.zsh.enable = true;

  system.configurationRevision = self.rev or self.dirtyRev or null;

  time.timeZone = "Europe/Helsinki";

  system.stateVersion = 6;

  nix.enable = false;

  security.pam.services.sudo_local.touchIdAuth = true;
}
