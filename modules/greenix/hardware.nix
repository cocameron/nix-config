{
  config,
  lib,
  inputs,
  ...
}: # Add 'inputs' here
{
  imports = [
    # Import hardware profiles directly here
    inputs.nixos-hardware.nixosModules.common-pc # Now 'inputs' is defined
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia-sync
    "${inputs.nixos-hardware.outPath}/common/gpu/nvidia/ampere"
  ];

  config = {
    hardware.nvidia = {
      prime = {
        amdgpuBusId = "PCI:12:0:0";
        nvidiaBusId = "PCI:1:0:0";
      };
      # Disable power management for better gaming performance
      powerManagement.enable = false;
      # Disable force full composition pipeline for better gaming performance
      forceFullCompositionPipeline = false;
    };
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # Enable sound with pipewire.
    hardware.pulseaudio.enable = false;
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
    };
  };
}
