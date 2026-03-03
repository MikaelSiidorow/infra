{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./disko.nix
    ./k3s.nix
    ./headscale.nix
  ];

  # System
  system.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;

  # Nix settings
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
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
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "virtio_pci"
    "virtio_scsi"
    "xhci_pci"
    "sd_mod"
    "sr_mod"
  ];
  boot.kernelModules = [ ];

  # Networking
  networking = {
    hostName = "k8s-server";
    useDHCP = lib.mkDefault true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        80 # HTTP
        443 # HTTPS
      ];
      interfaces."cni0".allowedTCPPorts = [
        5432 # PostgreSQL from K8s pods only
      ];
    };
  };

  # Timezone
  time.timeZone = "Europe/Helsinki";

  # Users
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBHSw1Hq0dCnEC2j78BqNKzP+hrn+MLppWELfHgVNCaG" # personal
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOia2sNQKFyftl4aDTHLGRhL3l54oPQRB49LVLWyevg7" # deploy key
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

  # PostgreSQL
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    settings = {
      listen_addresses = lib.mkForce "127.0.0.1,10.42.0.1";
      wal_level = "logical";
    };
    authentication = ''
      # K8s pod network (default CIDR for K3s)
      host all all 10.42.0.0/16 scram-sha-256
      # K3s service network
      host all all 10.43.0.0/16 scram-sha-256
    '';
    ensureDatabases = [
      "refinery"
      "marginalia"
      "marginalia_cvr"
      "marginalia_cdb"
    ];
    ensureUsers = [
      {
        name = "refinery";
        ensureDBOwnership = true;
      }
      {
        name = "marginalia";
        ensureDBOwnership = true;
      }
    ];
    # Runs only on first cluster init (fresh deploy)
    initialScript = pkgs.writeText "pg-init.sql" ''
      ALTER ROLE refinery WITH REPLICATION;
      ALTER ROLE marginalia WITH SUPERUSER REPLICATION;
      GRANT ALL PRIVILEGES ON DATABASE marginalia_cvr TO marginalia;
      GRANT ALL PRIVILEGES ON DATABASE marginalia_cdb TO marginalia;
    '';
  };

  # zero-cache needs REPLICATION for logical replication.
  # initialScript only runs on first cluster init, so this systemd
  # oneshot ensures REPLICATION is granted on existing clusters too.
  systemd.services.postgresql-grant-replication = {
    description = "Grant REPLICATION to PostgreSQL roles for zero-cache";
    after = [ "postgresql.service" "postgresql-setup.service" ];
    requires = [ "postgresql.service" "postgresql-setup.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
    };
    script = ''
      ${config.services.postgresql.package}/bin/psql -c "ALTER ROLE refinery WITH REPLICATION;"
      ${config.services.postgresql.package}/bin/psql -c "ALTER ROLE marginalia WITH SUPERUSER REPLICATION;"
      ${config.services.postgresql.package}/bin/psql -c "GRANT ALL PRIVILEGES ON DATABASE marginalia_cvr TO marginalia;"
      ${config.services.postgresql.package}/bin/psql -c "GRANT ALL PRIVILEGES ON DATABASE marginalia_cdb TO marginalia;"
    '';
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
