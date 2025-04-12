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
    inputs.nixos-wsl.nixosModules.default
    ./modules/nix/base.nix
  ];

  config = {

    #Provide a default hostname
    networking.hostName = lib.mkDefault "nixlab";
    networking.useDHCP = lib.mkDefault true;

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
          _1password-cli
        ];
      };
    };

    services.cloud-init.network.enable = true;
    system.stateVersion = lib.mkDefault "24.05";
  };
}
