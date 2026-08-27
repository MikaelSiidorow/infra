{
  pkgs,
  username,
  ...
}:
{
  imports = [ ../../modules/common ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "ntfs" ];
  };

  networking = {
    hostName = "hestia";
    networkmanager.enable = false;
  };

  time.timeZone = "Europe/Helsinki";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "Mikael Siidorow";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBHSw1Hq0dCnEC2j78BqNKzP+hrn+MLppWELfHgVNCaG"
    ];
  };

  environment.systemPackages = with pkgs; [
    ddrescue
    git
    ntfs3g
    rsync
    smartmontools
    vim
  ];

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # This is the release used for the initial installation. Do not change it.
  system.stateVersion = "26.05";
}
