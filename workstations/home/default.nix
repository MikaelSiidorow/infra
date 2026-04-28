# Home-manager configuration entry point
{
  lib,
  isDarwin ? false,
  ...
}:
{
  imports = [
    ./packages.nix
    ./direnv.nix
    ./git.nix
    ./zsh.nix
    ./scripts.nix
    ./applications.nix
    ./firefox.nix
    ./package-managers
  ]
  ++ lib.optionals isDarwin [
    ./skhd.nix
  ]
  ++ lib.optionals (!isDarwin) [
    ./applications-linux.nix
    ./gnome.nix
    ./zed.nix
  ];

  home = {
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;
}
