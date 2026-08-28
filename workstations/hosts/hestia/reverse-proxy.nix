{
  services.caddy = {
    enable = true;

    virtualHosts = {
      "http://ha.home.arpa".extraConfig = ''
        reverse_proxy 127.0.0.1:8123
      '';

      "http://zigbee.home.arpa".extraConfig = ''
        reverse_proxy 127.0.0.1:8080
      '';
    };
  };

  # Keep the backend ports open during the initial rollout. Once both proxies
  # are verified, HA and Zigbee2MQTT can bind to loopback and only HTTP needs
  # to be exposed on the LAN.
  networking.firewall.interfaces.enp31s0.allowedTCPPorts = [ 80 ];
}
