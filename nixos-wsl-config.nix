{
  inputs,
  pkgs,
  ...
}:
{

  imports = [
    inputs.home-manager.nixosModules.default
    inputs.nixos-wsl.nixosModules.default
    ./modules/nix/base.nix
  ];

  environment.systemPackages = [
    pkgs.pinentry-curses
  ];

  wsl = {
    enable = true;
    defaultUser = "colin";
  };

  programs.zsh.enable = true;
  security.sudo.wheelNeedsPassword = false;

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

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
