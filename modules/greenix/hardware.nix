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
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia # Direct NVIDIA, no PRIME
    "${inputs.nixos-hardware.outPath}/common/gpu/nvidia/ampere"
  ];

  config = {
    # Enable hardware graphics/OpenGL support
    hardware.graphics = {
      enable = true;
      enable32Bit = true;  # For 32-bit applications
    };
    hardware.firmware = [
  (pkgs.runCommand "sony-tv-edid-firmware" {} ''
    mkdir -p $out/lib/firmware/edid
    cp ${./sony-tv.edid} $out/lib/firmware/edid/sony-tv.edid
  '')
];

    hardware.nvidia = {
      # Direct NVIDIA GPU usage - no PRIME (cable plugged into GPU)
      prime.sync.enable = lib.mkForce false; # Explicitly disable PRIME
      prime.offload.enable = lib.mkForce false; # Explicitly disable PRIME offload
      # Disable power management for better gaming performance
      powerManagement.enable = false;
      # Enable modesetting for better Wayland support
      modesetting.enable = true;
      # Disable force full composition pipeline - let compositor handle sync
      forceFullCompositionPipeline = false;

      # Use open-source kernel modules (recommended for Ampere and newer)
      open = true;

      # Package selection - use latest stable
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      # Keep GPU initialized to prevent display signal loss
      nvidiaPersistenced = true;
    };
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # Xbox Wireless Adapter support
    boot.extraModulePackages = with config.boot.kernelPackages; [ xone ];
    boot.kernelModules = [ "xone" ];
    hardware.xone.enable = true;

    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;

      # Fix audio dropouts at 4K by increasing buffer sizes and priority
      extraConfig.pipewire = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 2048;  # Increased for 4K
          "default.clock.min-quantum" = 1024;
          "default.clock.max-quantum" = 4096;
        };
        "context.modules" = [
          {
            name = "libpipewire-module-rt";
            args = {
              "nice.level" = -11;  # Higher priority for audio
              "rt.prio" = 88;
              "rt.time.soft" = 2000000;
              "rt.time.hard" = 2000000;
            };
            flags = [ "ifexists" "nofail" ];
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
