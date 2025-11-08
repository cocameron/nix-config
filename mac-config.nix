{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    #inputs.mac-app-util.darwinModules.default
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

  users.users.colin = {
    home = "/Users/colin";
  };

  environment.systemPackages = with pkgs; [
    discord
    raycast
    pinentry_mac
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.colin = { ... }: {
      imports = [
        ./modules/common/home-manager/home.nix
        ./modules/mac/home-manager
      ];
    };
    extraSpecialArgs = {
      machinePackages = [ ];
    };
  };
  system.primaryUser = "colin";
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
      "steam"
      #   "ubiquiti-unifi-controller"
      #   "logitune"
      #   "zoom"
      #   "netspot"
      #   "tailscale"
      #   "orbstack"
      #   "rectangle-pro"
      #   "hiddenbar"
      #   "windows-app"
      #   "vlc"
      #   "firefox"
      #   "raycast"
      #   "pinentry-mac"
    ];#   
  };

  system.configurationRevision = inputs.rev or inputs.dirtyRev or null;

  system.stateVersion = 5;

  nixpkgs.hostPlatform = "aarch64-darwin";
}
