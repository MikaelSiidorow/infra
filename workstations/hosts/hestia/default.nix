{
  config,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../../modules/common
    ./home-assistant.nix
    ./reverse-proxy.nix
    ./zigbee.nix
  ];

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

  # Hestia builds and deploys the flake-pinned router configurations.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Dewclaw invokes the ordinary OpenSSH client when deploying the routers.
  # Select Hestia's dedicated key explicitly because it intentionally does not
  # use a default personal-key filename.
  programs.ssh.extraConfig = ''
    Host device 192.168.67.1 192.168.67.2
      IdentityFile ${config.sops.secrets.router-deploy-ssh-key.path}
      IdentitiesOnly yes
  '';

  sops.secrets.router-deploy-ssh-key = {
    owner = username;
    group = "users";
    mode = "0600";
  };

  # Join Hestia to the existing Headscale tailnet once with `tailscale up`.
  # The persisted node state keeps that enrollment, while NixOS owns the
  # forwarding and route-advertisement settings needed to reach the home LAN.
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
    extraSetFlags = [ "--advertise-routes=192.168.67.0/24" ];
  };

  # Tailscale subnet routers benefit from forwarding UDP GRO on the physical
  # interface. Apply the upstream-recommended flags on every boot.
  systemd.services.tailscale-udp-gro-forwarding = {
    description = "Optimize UDP GRO forwarding for Tailscale";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    before = [ "tailscaled.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.ethtool}/bin/ethtool -K enp31s0 rx-udp-gro-forwarding on rx-gro-list off";
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "Mikael Siidorow";
    linger = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBHSw1Hq0dCnEC2j78BqNKzP+hrn+MLppWELfHgVNCaG"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBHSw1Hq0dCnEC2j78BqNKzP+hrn+MLppWELfHgVNCaG"
  ];

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
