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
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.home-manager.nixosModules.default
    # inputs.nixos-wsl.nixosModules.default # WSL module not needed for nixlab
    ./modules/common/base.nix
    ./modules/common/nixos-base.nix # Import common NixOS settings
  ];

  config = {
    # Hostname and DHCP are handled by nixos-base.nix (using mkDefault)
    # Override hostname here if needed:
    networking.hostName = "nixlab"; # Set specific hostname for nixlab

    # Enable QEMU Guest for Proxmox
    services.qemuGuest.enable = lib.mkDefault true;

    # Use the boot drive for grub
    boot.loader.grub.enable = lib.mkDefault true;
    boot.loader.grub.devices = [ "nodev" ];

    boot.growPartition = lib.mkDefault true;

    # Allow remote updates with flakes and non-root users
    nix.settings.trusted-users = [
      "root"
      "@wheel"
    ];
    # services.avahi... # Moved to common/linux-base.nix

    # Specific packages needed for nixlab (pinentry-curses moved to common)
    environment.systemPackages = with pkgs; [
      vim # for emergencies
      git # for pulling nix flakes
      python3 # for ansible
    ];

    # security.sudo.wheelNeedsPassword = false; # Moved to common/linux-base.nix

    # Enable ssh
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };
    programs.ssh.startAgent = true;

    # Default filesystem
    fileSystems."/" = lib.mkDefault {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = "ext4";
    };

    # User 'colin' base defined in common/nixos-base.nix
    # Add machine-specific settings here (e.g., additional keys if needed).
    # users.users.colin.openssh.authorizedKeys.keys = [ ... ]; # Common key moved to nixos-base.nix

    # programs.zsh.enable = true; # Moved to common/linux-base.nix

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.colin = import ./modules/common/home-manager/home.nix;
      extraSpecialArgs = {
        machinePackages = with pkgs; [
          _1password-cli
        ];
      };
    };

    services.cloud-init.network.enable = true;
    system.stateVersion = lib.mkDefault "24.05";
  };
}
