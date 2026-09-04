{
  config,
  lib,
  pkgs,
  ...
}:
let
  startColima = pkgs.writeShellScript "start-colima-default" ''
    if ! /usr/sbin/pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
      echo "Rosetta is required by Colima; install it with: softwareupdate --install-rosetta --agree-to-license" >&2
      exit 1
    fi

    if ! /usr/bin/arch -x86_64 /usr/bin/true; then
      echo "Rosetta is installed but could not be activated" >&2
      exit 1
    fi

    export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    exec ${lib.getExe config.services.colima.package} start default -f --activate=true --save-config=false
  '';
in
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

  # Colima checks Rosetta's on-demand daemon with the system pgrep. Activate it
  # and make the macOS system tools visible before Colima starts.
  launchd.agents."colima-default".config.ProgramArguments = lib.mkForce [ "${startColima}" ];
}
