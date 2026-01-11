{
  config,
  inputs,
  pkgs,
  modulesPath,
  lib,
  ...
}:
let
  constants = import ./modules/common/constants.nix;
in
{
  imports = [
    # Base NixOS settings
    ./modules/common/base.nix
    # Common NixOS settings
    ./modules/common/nixos-base.nix

    # Greenix specific modules
    ./modules/greenix/boot.nix
    ./modules/greenix/desktop.nix
    ./modules/greenix/gaming.nix
    ./modules/greenix/hardware.nix
    ./modules/greenix/jovian.nix
    ./modules/greenix/packages.nix
    ./modules/greenix/storage.nix
    ./modules/greenix/users.nix
    ./modules/greenix/virtual-display.nix

    # Home Manager integration
    inputs.home-manager.nixosModules.default
    # Noctalia shell
    inputs.noctalia.nixosModules.default
    # Secrets management
    inputs.sops-nix.nixosModules.default
    # Jovian NixOS for gaming optimizations
    inputs.jovian.nixosModules.jovian
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  config = {
    # Hostname
    networking.hostName = "greenix";
    networking.interfaces.enp11s0.wakeOnLan.enable = true;

    # Secrets management
    sops = {
      defaultSopsFile = "/var/lib/sops-nix/secrets.yaml";
      validateSopsFiles = false;
      age = {
        keyFile = "/var/lib/sops-nix/keys.txt";
      };
      secrets.colin-password = {
        neededForUsers = true;
      };
    };

    services.gnome.gcr-ssh-agent.enable = true;
    fonts.packages = with pkgs; [
      nerd-fonts.iosevka-term-slab
      nerd-fonts.noto
      nerd-fonts.symbols-only
    ];
    # Home Manager configuration
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${constants.primaryUser}.imports = [
        ./modules/greenix/home-manager/default.nix
        inputs.plasma-manager.homeModules.plasma-manager
        inputs.nixvim.homeModules.nixvim
      ];
      extraSpecialArgs = {
        machinePackages = [ ];
        nixosConfig = config;
        inherit inputs;
      };
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data were taken. It's perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    system.stateVersion = "24.11"; # Did you read the comment?
  };
}
