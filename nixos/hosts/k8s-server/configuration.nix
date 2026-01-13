{ config, pkgs, lib, ... }:

{
  imports = [
    ./disko.nix
    ./k3s.nix
  ];

  # System
  system.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;

  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Boot - disko handles grub configuration for BIOS/GPT

  # Hetzner Cloud VM settings
  boot.initrd.availableKernelModules = [ "ata_piix" "virtio_pci" "virtio_scsi" "xhci_pci" "sd_mod" "sr_mod" ];
  boot.kernelModules = [ ];

  # Networking
  networking = {
    hostName = "k8s-server";
    useDHCP = lib.mkDefault true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22    # SSH
        80    # HTTP
        443   # HTTPS
        6443  # K3s API
      ];
    };
  };

  # Timezone
  time.timeZone = "Europe/Helsinki";

  # Users
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBHSw1Hq0dCnEC2j78BqNKzP+hrn+MLppWELfHgVNCaG"
    ];
  };

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # Basic packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    curl
    wget
    jq
    k9s
    kubectl
    kubernetes-helm
  ];
}
