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
    customLovelaceModules = [
      unstablePkgs.home-assistant-custom-lovelace-modules.kiosk-mode
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
      lovelace.dashboards.nixos-lovelace = {
        mode = "yaml";
        filename = "ui-lovelace.yaml";
        title = "Information display";
        icon = "mdi:view-dashboard-outline";
        show_in_sidebar = true;
        require_admin = false;
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

    # A separate read-only dashboard managed by Nix. The normal Overview
    # dashboard remains in storage mode and editable through the UI.
    lovelaceConfig = {
      title = "Information display";
      kiosk_mode.kiosk = true;
      views = [
        {
          title = "Departures";
          path = "departures";
          icon = "mdi:bus-clock";
          cards = [
            {
              type = "markdown";
              title = "Pohjantori · Louhentie · E2052";
              entity_id = [ "sensor.pohjantori_departures" ];
              content = ''
                {% set departures =
                  state_attr('sensor.pohjantori_departures', 'stoptimesWithoutPatterns')
                  or []
                %}
                {% set buses = departures
                  | selectattr('trip.route.shortName', 'in', ['111', '113'])
                  | list
                %}

                {% if buses %}
                <table role="presentation" width="100%">
                {% for departure in buses[:3] %}
                  {% set timestamp =
                    departure.serviceDay + departure.realtimeDeparture
                  %}
                  {% set seconds = timestamp - as_timestamp(now()) %}
                  {% if seconds <= 30 %}
                    {% set relative_time = 'Now' %}
                  {% elif seconds < 90 %}
                    {% set relative_time = '~1 min' %}
                  {% else %}
                    {% set relative_time =
                      ((seconds / 60) | round(0, 'ceil') | int | string) + ' min'
                    %}
                  {% endif %}
                  <tr>
                    <td width="15%"><strong>{{ departure.trip.route.shortName }}</strong></td>
                    <td>{{ departure.headsign }}</td>
                    <td width="30%" align="right"><strong>{{ relative_time }}</strong><br><small>{{ timestamp | timestamp_custom('%H:%M', true) }}</small></td>
                  </tr>
                {% endfor %}
                </table>
                {% else %}
                No upcoming 111 or 113 departures.
                {% endif %}
              '';
            }
            {
              type = "markdown";
              title = "Mythos Wi-Fi";
              content = ''
                ![Mythos Wi-Fi QR code](/local/mythos-wifi.png)
              '';
            }
            {
              type = "vertical-stack";
              cards = [
                {
                  type = "heading";
                  heading = "Home status";
                  icon = "mdi:home-analytics";
                }
                {
                  type = "grid";
                  columns = 2;
                  square = false;
                  cards = [
                    {
                      type = "tile";
                      entity = "sensor.bathroom_thermometer_temperature";
                      name = "Bathroom temperature";
                    }
                    {
                      type = "tile";
                      entity = "sensor.bathroom_thermometer_humidity";
                      name = "Bathroom humidity";
                    }
                    {
                      type = "tile";
                      entity = "switch.washing_machine_plug";
                      name = "Washing machine";
                      tap_action.action = "none";
                      icon_tap_action.action = "none";
                    }
                    {
                      type = "tile";
                      entity = "switch.pc_plug";
                      name = "PC";
                      tap_action.action = "none";
                      icon_tap_action.action = "none";
                    }
                  ];
                }
              ];
            }
          ];
        }
      ];
    };
  };

  # Home Assistant resolves !secret values from secrets.yaml next to its
  # generated configuration. The rendered file lives in /run and never in
  # the Nix store; only this symlink is placed in Home Assistant's state dir.
  sops = {
    secrets = {
      digitransit-api-key = { };
      mythos-wifi-qr-payload = {
        owner = "hass";
        group = "hass";
        mode = "0400";
      };
    };
    templates."home-assistant-secrets.yaml" = {
      owner = "hass";
      group = "hass";
      mode = "0400";
      content = ''
        digitransit_api_key: ${config.sops.placeholder.digitransit-api-key}
      '';
    };
  };

  systemd = {
    # Keep configuration.yaml declarative while allowing Home Assistant to
    # manage automations, scenes, and scripts created through the UI.
    tmpfiles.rules =
      let
        configDir = config.services.home-assistant.configDir;
      in
      [
        "f ${configDir}/automations.yaml 0600 hass hass -"
        "f ${configDir}/scenes.yaml 0600 hass hass -"
        "f ${configDir}/scripts.yaml 0600 hass hass -"
        "L+ ${configDir}/secrets.yaml - - - - ${config.sops.templates."home-assistant-secrets.yaml".path}"
      ];

    services = {
      # Restart Home Assistant when the encrypted source changes. This replaces
      # sops-nix's deprecated activation-script restartUnits mechanism.
      home-assistant.restartTriggers = [
        config.sops.secrets.digitransit-api-key.sopsFileHash
      ];

      # Generate the Wi-Fi QR code from its runtime secret. The QR payload and
      # resulting image never enter the Nix store.
      home-assistant-wifi-qr = {
        description = "Generate the Mythos Wi-Fi QR code";
        wantedBy = [ "multi-user.target" ];
        before = [ "home-assistant.service" ];
        requiredBy = [ "home-assistant.service" ];
        restartTriggers = [ config.sops.secrets.mythos-wifi-qr-payload.sopsFileHash ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "hass";
          Group = "hass";
          UMask = "0077";
        };
        script = ''
          set -euo pipefail
          install -d -m 0700 ${config.services.home-assistant.configDir}/www
          payload="$(< ${config.sops.secrets.mythos-wifi-qr-payload.path})"
          test -n "$payload"
          printf '%s' "$payload" \
            | ${pkgs.qrencode}/bin/qrencode \
                -t PNG -l Q -s 8 -m 2 \
                -o ${config.services.home-assistant.configDir}/www/mythos-wifi.png
        '';
      };
    };
  };

  networking.firewall.interfaces.enp31s0.allowedTCPPorts = [ 8123 ];
}
