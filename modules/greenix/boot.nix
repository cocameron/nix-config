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
    boot.kernelModules = [ "kvm-amd" "tcp_bbr" ];
    boot.extraModulePackages = [ ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Use latest kernel for better hardware support and gaming performance
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # Gaming-specific kernel parameters
    boot.kernel.sysctl = {
      # Required for some games (DayZ, Hogwarts Legacy, CS2, etc.)
      # Modern standard value adopted by Fedora, Arch, Ubuntu
      "vm.max_map_count" = 1048576;
      # Reduce swapping for better gaming performance
      "vm.swappiness" = 10;
      # Network optimizations for gaming (BBR congestion control)
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.default_qdisc" = "fq";
    };

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/fe922cc1-0757-448c-95f1-4ca3f720fca1";
      fsType = "ext4";
      options = [ "noatime" ]; # Reduce disk writes (nodiratime is implied)
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
