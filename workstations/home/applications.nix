# Desktop applications - platform-agnostic
{ pkgs, ... }:
{
  programs = {
    # Ghostty: Not in nixpkgs for macOS yet
    # macOS: install via Homebrew (see modules/darwin/homebrew.nix)
    # Linux: uses wrapped version (see home/applications-linux.nix)

    vscode = {
      enable = true;
    };

  };
}
