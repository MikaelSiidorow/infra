{ config, pkgs, ... }:

let
  manifestDir = "/var/lib/rancher/k3s/server/manifests";

  traefikChart = pkgs.writeText "traefik-helmchart.yaml" ''
    apiVersion: helm.cattle.io/v1
    kind: HelmChart
    metadata:
      name: traefik
      namespace: kube-system
    spec:
      chart: traefik
      repo: https://traefik.github.io/charts
      targetNamespace: traefik
      createNamespace: true
      version: 39.0.2
      valuesContent: |-
        ports:
          web:
            http:
              redirections:
                entryPoint:
                  to: websecure
                  scheme: https
  '';

  certManagerChart = pkgs.writeText "cert-manager-helmchart.yaml" ''
    apiVersion: helm.cattle.io/v1
    kind: HelmChart
    metadata:
      name: cert-manager
      namespace: kube-system
    spec:
      chart: cert-manager
      repo: https://charts.jetstack.io
      targetNamespace: cert-manager
      createNamespace: true
      valuesContent: |-
        crds:
          enabled: true
  '';

  argocdChart = pkgs.writeText "argocd-helmchart.yaml" ''
    apiVersion: helm.cattle.io/v1
    kind: HelmChart
    metadata:
      name: argocd
      namespace: kube-system
    spec:
      chart: argo-cd
      repo: https://argoproj.github.io/argo-helm
      targetNamespace: argocd
      createNamespace: true
      version: 9.0.5
      valuesContent: |-
        configs:
          params:
            server.insecure: "true"
  '';

  argocdBootstrap = pkgs.writeText "argocd-bootstrap.yaml" ''
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: bootstrap
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: https://github.com/MikaelSiidorow/infra.git
        targetRevision: main
        path: k8s/apps
      destination:
        server: https://kubernetes.default.svc
        namespace: argocd
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
  '';

  clusterIssuer = pkgs.writeText "cluster-issuer.yaml" ''
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: mikael@siidorow.com
        privateKeySecretRef:
          name: letsencrypt-prod-account-key
        solvers:
          - http01:
              ingress:
                ingressClassName: traefik
  '';
in
{
  # K3s - Lightweight Kubernetes
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--disable=traefik" # Deploy our own Traefik via HelmChart CRD
    ];
  };

  # Auto-deploy infrastructure manifests via K3s
  systemd.tmpfiles.rules = [
    "L+ ${manifestDir}/traefik-helmchart.yaml - - - - ${traefikChart}"
    "L+ ${manifestDir}/cert-manager-helmchart.yaml - - - - ${certManagerChart}"
    "L+ ${manifestDir}/cluster-issuer.yaml - - - - ${clusterIssuer}"
    "L+ ${manifestDir}/argocd-helmchart.yaml - - - - ${argocdChart}"
    "L+ ${manifestDir}/argocd-bootstrap.yaml - - - - ${argocdBootstrap}"
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

  # Kubeconfig for root
  environment.variables = {
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };
}
