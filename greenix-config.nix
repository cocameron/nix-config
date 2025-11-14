{
  config,
  inputs,
  pkgs,
  modulesPath,
  lib,
  pkgs-unstable,
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
    ./modules/greenix/packages.nix
    ./modules/greenix/users.nix

    # Home Manager integration
    inputs.home-manager.nixosModules.default
  ];

  config = {
    # Hostname
    networking.hostName = "greenix";

    # Home Manager configuration
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${constants.primaryUser}.imports = [ ./modules/greenix/home-manager/default.nix ];
      extraSpecialArgs = {
        machinePackages = [ ];
        nixosConfig = config;
        inherit inputs pkgs-unstable;
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
