{
  config,
  inputs,
  pkgs,
  modulesPath,
  lib,
  system,
  pkgs-unstable,
  ...
}:
{
  imports = [
    # Base NixOS settings
    ./modules/common/base.nix
    # Common NixOS settings
    ./modules/common/nixos-base.nix

    # Greenix specific modules (explicit imports)
    ./modules/greenix/boot.nix
    ./modules/greenix/desktop.nix
    ./modules/greenix/gaming.nix
    ./modules/greenix/hardware.nix
    ./modules/greenix/packages.nix
    ./modules/greenix/users.nix
    # ./modules/greenix/services.nix # Assuming this might exist or be added later

    # Home Manager integration
    inputs.home-manager.nixosModules.default
  ];

  config = {
    # This value determines the NixOS release from which the default
    # settings for stateful data were taken. It's perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux"; # From hardware scan
    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
