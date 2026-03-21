{ config, pkgs, ... }:
{
  services.headscale = {
    enable = true;
    address = "0.0.0.0"; # Needs to be reachable from K8s CNI bridge (10.42.0.1); Hetzner firewall blocks 8080 externally
    port = 8080;
    settings = {
      server_url = "https://hs.miksu.app";
      dns = {
        magic_dns = true;
        base_domain = "vpn.miksu.app";
        nameservers.split = {
          "miksu.app" = [
            "1.1.1.1"
            "1.0.0.1"
          ];
        };
        extra_records = [
          {
            name = "argocd.miksu.app";
            type = "A";
            value = "100.64.0.1";
          }
          {
            name = "grafana.miksu.app";
            type = "A";
            value = "100.64.0.1";
          }
        ];
      };
      prefixes = {
        v4 = "100.64.0.0/10";
        v6 = "fd7a:115c:a1e0::/48";
      };
      derp.server = {
        enabled = true;
        region_id = 999;
        region_code = "headscale";
        region_name = "Headscale Embedded DERP";
        stun_listen_addr = "0.0.0.0:3478";
      };
    };
  };

  services.tailscale.enable = true;

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ 3478 ];
    checkReversePath = "loose";
  };

  environment.systemPackages = [ config.services.headscale.package ];
}
