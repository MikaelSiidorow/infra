# MacBook Air M3 (aarch64-darwin) host configuration
{
  self,
  pkgs,
  username,
  inputs,
  ...
}:
{
  imports = [
    ../../modules/darwin
  ];

  # Host-specific settings
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Primary user for this machine
  system.primaryUser = username;
  users.users.${username}.home = "/Users/${username}";
}
