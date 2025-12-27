{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: # Add 'inputs' here
{
  imports = [
    # Import hardware profiles directly here
    inputs.nixos-hardware.nixosModules.common-pc # Now 'inputs' is defined
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd # AMD GPU support
  ];

  config = {
    # Workaround for xone driver firmware naming mismatch
    # See: https://github.com/NixOS/nixpkgs/issues/471331
    nixpkgs.overlays = [
      (final: prev: {
        xow_dongle-firmware = prev.xow_dongle-firmware.overrideAttrs (old: {
          installPhase = ''
            install -Dm644 xow_dongle.bin $out/lib/firmware/xow_dongle.bin
            install -Dm644 xow_dongle_045e_02e6.bin $out/lib/firmware/xone_dongle_02e6.bin
          '';
        });
      })
    ];
    # Enable hardware graphics/OpenGL support
    hardware.graphics = {
      enable = true;
      enable32Bit = true; # For 32-bit applications
    };
    hardware.firmware = [
      (pkgs.runCommand "sony-tv-edid-firmware" { } ''
        mkdir -p $out/lib/firmware/edid
        cp ${./sony-tv.edid} $out/lib/firmware/edid/sony-tv.edid
      '')
    ];

    # Enable firmware for AMD GPU and CPU
    hardware.enableRedistributableFirmware = true;

    # AMD GPU configuration
    # The amdgpu driver is loaded automatically by the common-gpu-amd module
    # Enable hardware video acceleration
    hardware.amdgpu = {
      # Enable AMD GPU early KMS (kernel mode setting)
      initrd.enable = true;
      # Enable OpenCL support for compute workloads
      opencl.enable = true;
    };

    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # Xbox Wireless Adapter support
    boot.extraModulePackages = with config.boot.kernelPackages; [ xone ];
    boot.kernelModules = [ "xone" ];
    hardware.xone.enable = true;

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;

      extraConfig.pipewire = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 32;
	  "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 32;
        };
        "context.modules" = [
          {
            name = "libpipewire-module-rt";
            args = {
              "nice.level" = -11; # Higher priority for audio
              "rt.prio" = 88;
              "rt.time.soft" = 2000000;
              "rt.time.hard" = 2000000;
            };
            flags = [
              "ifexists"
              "nofail"
            ];
          }
        ];
      };

      extraConfig.pipewire-pulse = {
        "pulse.properties" = {
          "pulse.min.req" = "2048/48000";
          "pulse.default.req" = "2048/48000";
          "pulse.max.req" = "4096/48000";
          "pulse.min.quantum" = "2048/48000";
          "pulse.max.quantum" = "4096/48000";
        };
      };
    };
  };
}
