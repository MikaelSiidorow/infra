# Lenovo ThinkPad X1 Carbon Gen 9 (20XW005NMX).
# Storage identifiers match the current LUKS -> LVM installation.
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Tiger Lake, Thunderbolt 4, and Samsung NVMe storage.
  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];

      luks.devices.cryptdata = {
        device = "/dev/disk/by-uuid/d2c56f4e-063c-494d-b1cd-990c5cb32664";
      };
    };
    kernelModules = [ "kvm-intel" ];
  };

  fileSystems."/" = {
    # The filesystem UUID changes when this LV is formatted during installation.
    device = "/dev/mapper/data-root";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  fileSystems."/boot" = {
    # Use PARTUUID because the EFI and recovery filesystems share a FAT UUID.
    device = "/dev/disk/by-partuuid/181cbe5b-0809-41cf-8bab-d262e7748942";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # Match the existing Pop!_OS cryptswap setup. Random encryption intentionally
  # prevents hibernation, but avoids storing a persistent swap encryption key.
  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/f625397a-0e9b-4311-b5c3-a02a07f3bece";
      randomEncryption = {
        enable = true;
        cipher = "aes-xts-plain64";
        keySize = 512;
      };
    }
  ];

  # Intel CPU
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
