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

  # Notify once per new commit when GitHub main is ahead of the running system.
  nixConfigUpdateCheck = pkgs.writeShellApplication {
    name = "nix-config-update-check";
    runtimeInputs = [
      pkgs.git
      pkgs.jq
    ];
    text = ''
      repo="$HOME/nix-config"
      state="''${XDG_CACHE_HOME:-$HOME/.cache}/nix-config-update-check"

      remote=$(git ls-remote https://github.com/MikaelSiidorow/nix-config refs/heads/main | cut -f1)
      current=$(/run/current-system/sw/bin/darwin-version --json | jq -r '.configurationRevision // empty')
      # Builds from uncommitted changes record "<rev>-dirty"; compare their base commit.
      current="''${current%-dirty}"

      [ -n "$current" ] || exit 0
      [ -n "$remote" ] || exit 0
      [ "$remote" != "$current" ] || exit 0

      # Running system already includes remote main (e.g. unpushed local commits).
      if git -C "$repo" cat-file -e "$remote^{commit}" 2>/dev/null &&
        git -C "$repo" merge-base --is-ancestor "$remote" "$current" 2>/dev/null; then
        exit 0
      fi

      [ "$(cat "$state" 2>/dev/null)" != "$remote" ] || exit 0

      /usr/bin/osascript -e 'display notification "New commits on GitHub main" with title "nix-config"'
      mkdir -p "$(dirname "$state")"
      echo "$remote" >"$state"
    '';
  };
in
{
  imports = [
    ./system.nix
    ./homebrew.nix
  ];

  environment.systemPackages = [
    # pkgs-unstable.notion-app # Now installed and updated by the enterprise MDM.
    scrollReverser
    pkgs.vim
  ];

  launchd.user.agents = {
    # Start Scroll Reverser in the user's GUI session at login. KeepAlive is
    # intentionally omitted so quitting the app does not immediately reopen it.
    scroll-reverser.serviceConfig = {
      Program = "${scrollReverser}/Applications/Scroll Reverser.app/Contents/MacOS/Scroll Reverser";
      RunAtLoad = true;
    };

    nix-config-update-check.serviceConfig = {
      Program = "${nixConfigUpdateCheck}/bin/nix-config-update-check";
      RunAtLoad = true;
      StartInterval = 2 * 60 * 60;
    };
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
