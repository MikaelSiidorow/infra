# NixOS laptop host configuration
{
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../../modules/nixos
    ./hardware-configuration.nix
  ];

  networking.hostName = "nixos-laptop";

  users.users.${username} = {
    isNormalUser = true;
    uid = 1000;
    description = "Mikael Siidorow";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "video" # for brightnessctl
      "input"
    ];
    shell = pkgs.zsh;
  };

  system.stateVersion = "24.11";
}
