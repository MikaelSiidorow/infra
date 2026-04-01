# Darwin (macOS) specific modules
{
  self,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./system.nix
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

  # Disable nix-darwin's Nix daemon management (using Determinate Systems installer)
  nix.enable = false;

  security.pam.services.sudo_local.touchIdAuth = true;

  # Cap per-process file descriptors to prevent login(1) from hanging
  # when iterating FDs (e.g. cmux/Ghostty terminal spawning)
  launchd.daemons.sysctl-maxfilesperproc = {
    command = "/usr/sbin/sysctl kern.maxfilesperproc=65536";
    serviceConfig = {
      RunAtLoad = true;
      LaunchOnlyOnce = true;
    };
  };
}
