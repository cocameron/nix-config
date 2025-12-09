{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = {
    # Bootloader.
    boot.loader.refind.enable = true;
    boot.loader.refind.extraConfig = "include themes/refind-theme/theme.conf";
    boot.loader.refind.maxGenerations = 2;
    boot.loader.refind.additionalFiles =
      let
        themeDir = ./refind-theme;
        # Recursively find all files in a directory
        listFilesRecursive =
          dir: path:
          let
            entries = builtins.readDir (dir + path);
          in
          lib.flatten (
            lib.mapAttrsToList (
              name: type:
              if type == "directory" then listFilesRecursive dir "${path}/${name}" else "${path}/${name}"
            ) entries
          );
        # Get all files relative to theme directory
        allFiles = listFilesRecursive themeDir "";
      in
      builtins.listToAttrs (
        map (file: {
          name = "themes/refind-theme${file}";
          value = themeDir + file;
        }) allFiles
      );
    boot.loader.grub.enable = false;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];
    boot.initrd.kernelModules = [ ];
    boot.plymouth = {
      enable = true;
      theme = "rings";
      themePackages = with pkgs; [
        # By default we would install all themes
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "rings" ];
        })
      ];
    };

    # Enable "Silent boot"
    boot.consoleLogLevel = 3;
    boot.initrd.verbose = false;
    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key
    # It will just not appear on screen unless a key is pressed

    # Compress initrd more aggressively to fit in small boot partition
    boot.initrd.compressor = "zstd";
    boot.initrd.compressorArgs = [
      "-19"
      "-T0"
    ];
    #boot.initrd.extraFiles."lib/firmware/edid/sony-tv.edid".source = pkgs.copyPathToStore ./sony-tv.edid;
    # Strip initrd to minimal size
    boot.initrd.includeDefaultModules = false;
    # Load AMD GPU and other modules during normal boot (amdgpu loaded by initrd KMS)
    boot.kernelModules = [
      "kvm-amd"
      "tcp_bbr"
    ];
    boot.extraModulePackages = [ ];
    #boot.loader.systemd-boot.enable = true;
    #boot.loader.systemd-boot.configurationLimit = 2;
    #boot.loader.efi.canTouchEfiVariables = true;

    # Use LTS kernel for smaller initrd (temporary workaround for small boot partition)
    # TODO: Resize boot partition to 512MB+ and switch back to linuxPackages_latest
    boot.kernelPackages = pkgs.linuxPackages;

    # Kernel parameters for AMD GPU + Gamescope
    boot.kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "rd.systemd.show_status=false"
      "vt.global_cursor_default=0"
    ];

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
      device = "/dev/disk/by-uuid/3ED0-77B6";
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
