{ config, pkgs, ... }:

{
  # K3s - Lightweight Kubernetes
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--disable=traefik"  # We'll use ingress-nginx or traefik via helm for more control
      "--write-kubeconfig-mode=644"
    ];
  };

  # Open ports for K3s networking
  networking.firewall.allowedTCPPorts = [
    10250  # Kubelet metrics
  ];

  # Ensure k3s can manage iptables
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Alias for convenience
  environment.shellAliases = {
    k = "kubectl";
  };

  # Kubeconfig available system-wide
  environment.variables = {
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };
}
