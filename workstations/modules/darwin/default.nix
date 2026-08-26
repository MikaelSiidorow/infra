# Darwin (macOS) specific modules
{
  self,
  pkgs,
  ...
}:
let
  # The upstream zip contains an AppleDouble sidecar that unzip materializes as
  # a regular file, invalidating the otherwise notarized app's code signature.
  scrollReverser = pkgs.scroll-reverser.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      rm -f "$out/Applications/Scroll Reverser.app/Contents/Resources/._IntroShot.png"
    '';
  });
in
{
  imports = [
    ./system.nix
    ./homebrew.nix
  ];

  environment.systemPackages = [
    scrollReverser
    pkgs.vim
  ];

  # Start Scroll Reverser in the user's GUI session at login. KeepAlive is
  # intentionally omitted so quitting the app does not immediately reopen it.
  launchd.user.agents.scroll-reverser.serviceConfig = {
    Program = "${scrollReverser}/Applications/Scroll Reverser.app/Contents/MacOS/Scroll Reverser";
    RunAtLoad = true;
  };

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
