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
let
  # Imports all .nix files directly within a given directory path.
  # Assumes paths are relative to the file calling this function.
  importModulesFromDir =
    dirPath:
    lib.mapAttrsToList (name: value: dirPath + "/${name}") (
      lib.filterAttrs (n: v: lib.hasSuffix ".nix" n) (builtins.readDir dirPath)
    );
in
{
  imports =
    [
      # Base NixOS settings
      ./modules/common/base.nix
      # Common NixOS settings
      ./modules/common/nixos-base.nix

      # Import all NixOS modules within the greenix directory using the helper
    ]
    ++ importModulesFromDir ./modules/greenix
    ++ [
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
    system.stateVersion = "24.11"; # Did you read the comment?
  };
}
