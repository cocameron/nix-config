{ lib, ... }:
let
  constants = import ../common/constants.nix;
in
{
  config = {
    # security.sudo.wheelNeedsPassword = false; # Moved to common/linux-base.nix

    # User 'colin' base defined in common/nixos-base.nix
    # Add machine-specific settings here (e.g., additional keys if needed).
    # users.users.colin.openssh.authorizedKeys.keys = [ ... ]; # Common key moved to nixos-base.nix

    # Add NFS group access
    users.users.${constants.primaryUser}.extraGroups = [ "rust-users" ];

    # programs.zsh.enable = true; # Moved to common/base.nix

    # Home-manager configuration moved to greenix-config.nix to avoid duplication
  };
}
