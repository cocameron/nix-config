{
  config,
  inputs,
  pkgs,
  modulesPath,
  lib,
  system,
  ...
}:

{
  imports = [
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia-sync
    "${inputs.nixos-hardware.outPath}/common/gpu/nvidia/ampere"

    inputs.home-manager.nixosModules.default
    ./greenix-etc-config.nix
    ./modules/nix/base.nix
  ];

  config = {
    hardware.nvidia.prime = {
	amdgpuBusId = "PCI:12:0:0";
	nvidiaBusId = "PCI:1:0:0";
    };
    #Provide a default hostname
    networking.hostName = lib.mkDefault "greenix";
    networking.useDHCP = lib.mkDefault true;

       # Enable mDNS for `hostname.local` addresses
    services.avahi.enable = true;
    services.avahi.nssmdns = true;
    services.avahi.publish = {
      enable = true;
      addresses = true;
    };

    # Some sane packages we need on every system
    environment.systemPackages = with pkgs; [
      vim # for emergencies
      git # for pulling nix flakes
      python3 # for ansible
      pinentry-curses
    ];

    # Don't ask for passwords
    security.sudo.wheelNeedsPassword = false;

    users.users.colin = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWxH6KYmI6UCzu3j+HhnKMhFcDT1oyMilWG76qXF8yV"
      ];
    };

    programs.zsh.enable = true;

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.colin = import ./modules/home-manager/home.nix;
      extraSpecialArgs = {
        machinePackages = with pkgs; [
          _1password
	  _1password-gui
	  ghostty
        ];
      };
    };

    system.stateVersion = lib.mkDefault "24.05";
  };
}
