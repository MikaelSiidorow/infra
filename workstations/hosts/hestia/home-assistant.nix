{
  config,
  inputs,
  pkgs,
  ...
}:
let
  unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  digitransitQuery = builtins.toJSON {
    query = ''
      {
        stop(id: "HSL:2215221") {
          stoptimesWithoutPatterns(numberOfDepartures: 12) {
            serviceDay
            scheduledDeparture
            realtimeDeparture
            departureDelay
            realtime
            realtimeState
            headsign
            trip {
              route {
                gtfsId
                shortName
              }
            }
          }
        }
      }
    '';
  };
in
{
  # Home Assistant moves faster than the NixOS stable release. Replace only
  # its stable module and package while keeping the rest of Hestia on stable.
  disabledModules = [ "services/home-automation/home-assistant.nix" ];
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/home-automation/home-assistant.nix"
  ];

  services.home-assistant = {
    enable = true;
    package = unstablePkgs.home-assistant.overrideAttrs (_: {
      doInstallCheck = false;
    });

    # Integrations added through the UI still need their Python dependencies
    # declared here.
    extraComponents = [
      "cast"
      "mqtt"
      "rest"
    ];

    config = {
      default_config = { };
      "automation ui" = "!include automations.yaml";
      "scene ui" = "!include scenes.yaml";
      "script ui" = "!include scripts.yaml";
      homeassistant = {
        name = "Home";
        time_zone = "Europe/Helsinki";
        unit_system = "metric";
      };

      rest = [
        {
          resource = "https://api.digitransit.fi/routing/v2/hsl/gtfs/v1";
          method = "POST";
          headers = {
            Content-Type = "application/json";
            digitransit-subscription-key = "!secret digitransit_api_key";
          };
          payload = digitransitQuery;
          scan_interval = 15;
          timeout = 10;
          sensor = [
            {
              name = "Pohjantori departures";
              unique_id = "pohjantori_departures";
              icon = "mdi:bus-clock";
              value_template = ''
                {{ value_json.data.stop.stoptimesWithoutPatterns
                   | selectattr('trip.route.shortName', 'in', ['111', '113'])
                   | list | count }}
              '';
              json_attributes_path = "$.data.stop";
              json_attributes = [ "stoptimesWithoutPatterns" ];
            }
          ];
        }
      ];
    };
  };

  # Home Assistant resolves !secret values from secrets.yaml next to its
  # generated configuration. The rendered file lives in /run and never in
  # the Nix store; only this symlink is placed in Home Assistant's state dir.
  sops.secrets.digitransit-api-key = { };
  sops.templates."home-assistant-secrets.yaml" = {
    owner = "hass";
    group = "hass";
    mode = "0400";
    restartUnits = [ "home-assistant.service" ];
    content = ''
      digitransit_api_key: ${config.sops.placeholder.digitransit-api-key}
    '';
  };

  # Keep configuration.yaml declarative while allowing Home Assistant to
  # manage automations, scenes, and scripts created through the UI.
  systemd.tmpfiles.rules =
    let
      configDir = config.services.home-assistant.configDir;
    in
    [
      "f ${configDir}/automations.yaml 0600 hass hass -"
      "f ${configDir}/scenes.yaml 0600 hass hass -"
      "f ${configDir}/scripts.yaml 0600 hass hass -"
      "L+ ${configDir}/secrets.yaml - - - - ${config.sops.templates."home-assistant-secrets.yaml".path}"
    ];

  networking.firewall.interfaces.enp31s0.allowedTCPPorts = [ 8123 ];
}
