{
  inputs,
  pkgs,
  ...
}:
let
  constants = import ./modules/common/constants.nix;
in
{
  imports = [
    # inputs.mac-app-util.darwinModules.default
    inputs.home-manager.darwinModules.home-manager
    (
      { ... }:
      {
        home-manager.sharedModules = [
          # inputs.mac-app-util.homeManagerModules.default
        ];
      }
    )
    inputs.nix-homebrew.darwinModules.nix-homebrew
    ./modules/common/base.nix
  ];

  security.pam.services.sudo_local.touchIdAuth = true;

  users.users.${constants.primaryUser} = {
    home = "/Users/${constants.primaryUser}";
  };

  environment.systemPackages = with pkgs; [
    pinentry_mac
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.${constants.primaryUser} =
      { ... }:
      {
        imports = [
          ./modules/common/home-manager/home.nix
          ./modules/mac/home-manager
        ];
      };
    extraSpecialArgs = {
      machinePackages = [ ];
    };
  };
  system.primaryUser = constants.primaryUser;
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = constants.primaryUser;
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
      "steam"
      "discord"
      "ubiquiti-unifi-controller"
      "logitune"
      "zoom"
      #   "netspot"
      "tailscale"
      "orbstack"
      "rectangle-pro"
      "hiddenbar"
      "windows-app"
      "vlc"
      "firefox"
      #   "raycast"
      #   "pinentry-mac"
    ];
  };

  system.configurationRevision = inputs.rev or inputs.dirtyRev or null;

  system.stateVersion = 5;

  nixpkgs.hostPlatform = "aarch64-darwin";
}
