# Home-manager configuration entry point
{
  lib,
  isDarwin ? false,
  ...
}:
{
  imports =
    [
      ./packages.nix
      ./git.nix
      ./zsh.nix
      ./applications.nix
    ]
    ++ lib.optionals isDarwin [
      ./skhd.nix
    ];

  home = {
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;
}
