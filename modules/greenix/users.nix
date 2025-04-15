_:
{
  config = {
    # security.sudo.wheelNeedsPassword = false; # Moved to common/linux-base.nix

    # User 'colin' base defined in common/nixos-base.nix
    # Add machine-specific settings here (e.g., additional keys if needed).
    # users.users.colin.openssh.authorizedKeys.keys = [ ... ]; # Common key moved to nixos-base.nix

    # programs.zsh.enable = true; # Moved to common/base.nix

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.colin =
        { ... }:
        {
          imports = [
            ../common/home-manager/home.nix # Common home-manager config
            ./home-manager # Greenix specific home-manager config (new location)
          ];
        };
    };
  };
}
