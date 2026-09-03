{
  config,
  pkgs,
  ...
}:
{
  # Colima provides the engine; keep the Docker and Compose clients independent
  # from OrbStack while its context remains available during the migration.
  home.packages = with pkgs; [
    docker
    docker-compose
  ];

  services.colima = {
    enable = true;

    profiles = {
      default = {
        isActive = true;
        isService = true;
        setDockerHost = false;

        settings = {
          cpu = 8;
          disk = 250;
          memory = 16;

          arch = "host";
          runtime = "docker";

          kubernetes.enabled = false;

          vmType = "vz";
          rosetta = true;
          mountType = "virtiofs";

          mounts = [
            {
              location = "${config.home.homeDirectory}/Documents";
              writable = true;
            }
          ];
        };
      };
    };
  };
}
