{
  inputs,
  pkgs,
  ...
}:
{

  imports = [
    inputs.home-manager.nixosModules.default
    inputs.nixos-wsl.nixosModules.default
    ./modules/common/base.nix
    ./modules/common/nixos-base.nix # Import common NixOS settings
  ];

  # WSL-specific packages (pinentry-curses moved to common)
  # environment.systemPackages = []; # Add any WSL-specific system packages here if needed

  wsl = {
    enable = true;
    defaultUser = "colin";
  };

  # programs.zsh.enable = true; # Moved to common/linux-base.nix
  # security.sudo.wheelNeedsPassword = false; # Moved to common/linux-base.nix

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

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
