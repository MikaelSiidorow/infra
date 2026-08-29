{
  config,
  inputs,
  pkgs,
  ...
}:
let
  unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
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
    };
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
    ];

  networking.firewall.interfaces.enp31s0.allowedTCPPorts = [ 8123 ];
}
