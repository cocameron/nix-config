{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = {
    # Bootloader.
    boot.initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-amd" ];
    boot.extraModulePackages = [ ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/fe922cc1-0757-448c-95f1-4ca3f720fca1";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/0818-34DD";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    swapDevices = [ ];

    # bigger tty fonts - moved from hardware config
    console.font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
  };
}
