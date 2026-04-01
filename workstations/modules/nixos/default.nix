# NixOS system configuration
{ pkgs, ... }:
{
  # Boot
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  # Keep the NixOS kernel as the reliable default and expose CachyOS separately
  # in the boot menu.
  specialisation.cachyos.configuration.boot.kernelPackages =
    pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  # Locale
  time.timeZone = "Europe/Helsinki";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "fi_FI.UTF-8";
      LC_MONETARY = "fi_FI.UTF-8";
    };

    # Input method (Chinese Pinyin)
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [
          qt6Packages.fcitx5-chinese-addons
        ];
        settings.inputMethod = {
          GroupOrder."0" = "Default";
          "Groups/0" = {
            "Default Layout" = "fi";
            DefaultIM = "keyboard-fi";
            Name = "Default";
          };
          "Groups/0/Items/0".Name = "keyboard-fi";
          "Groups/0/Items/1" = {
            Layout = "fi";
            Name = "pinyin";
          };
        };
      };
    };
  };
  console.keyMap = "fi";

  # Networking
  networking.networkmanager.enable = true;

  # Mullvad's base resolver blocks ads, trackers, and malware. The "~." route
  # makes these global servers preferred over DNS learned from ordinary links.
  services = {
    xserver.xkb.layout = "fi";

    resolved = {
      enable = true;
      settings.Resolve = {
        DNS = [
          "194.242.2.4#base.dns.mullvad.net"
          "2a07:e340::4#base.dns.mullvad.net"
        ];
        FallbackDNS = [ ];
        DNSSEC = false;
        DNSOverTLS = true;
        Domains = [ "~." ];
      };
    };

    # Audio (PipeWire)
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # KDE Plasma desktop
    desktopManager.plasma6.enable = true;
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
      defaultSession = "plasma";
    };

    # Power management
    thermald.enable = true;
  };

  hardware = {
    # Bluetooth
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # GPU (Intel Iris Xe)
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  # Docker
  virtualisation.docker.enable = true;

  # Security
  security.polkit.enable = true;
  security.rtkit.enable = true; # for PipeWire

  # Fonts
  fonts.packages = with pkgs; [
    inter
    roboto-mono
    noto-fonts
    noto-fonts-cjk-sans
    nerd-fonts.symbols-only
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    gnumake
  ];

  # Enable zsh system-wide (needed for user shell)
  programs.zsh.enable = true;

  # Steam
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true;
  };

  # Allow unfree
  nixpkgs.config.allowUnfree = true;

  # Nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # CachyOS kernel binary cache
    substituters = [ "https://attic.xuyh0120.win/lantian" ];
    trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  };
}
