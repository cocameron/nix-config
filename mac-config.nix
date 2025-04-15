{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
    ./modules/common/base.nix
  ];
  environment.systemPackages = [
    pkgs.vim
    pkgs.raycast
    pkgs.pinentry_mac
  ];
  security.pam.enableSudoTouchIdAuth = true;

  users.users.colin = {
    home = "/Users/colin";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.colin = import ./modules/common/home-manager/home.nix;
    extraSpecialArgs = {
      machinePackages = [ ];
    };
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "colin";
    autoMigrate = true;
  };

  homebrew = {
    enable = true;
    global = {
      autoUpdate = true;
    };
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "zap";
    };
    casks = [
      "1password-cli"
      "1password"
      "ghostty"
    ];
  };

  system.configurationRevision = inputs.rev or inputs.dirtyRev or null;

  system.stateVersion = 5;

  nixpkgs.hostPlatform = "aarch64-darwin";
}
