# Hardware configuration placeholder for Lenovo ThinkPad (Intel TigerLake)
# IMPORTANT: Replace this with output of `nixos-generate-config` during install.
# The UUIDs below are placeholders and MUST be updated.
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Intel TigerLake modules
  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];

      # LUKS encryption — update UUID after install
      luks.devices."data-root" = {
        device = "/dev/disk/by-uuid/PLACEHOLDER-LUKS-UUID";
      };
    };
    kernelModules = [ "kvm-intel" ];
  };

  # Filesystems — update UUIDs after install
  fileSystems."/" = {
    device = "/dev/mapper/data-root";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/PLACEHOLDER-BOOT-UUID";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ ];

  # Intel CPU
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
