{ pkgs, lib, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      lutris
      (retroarch.withCores (cores: with cores; [
        dolphin
      ]))
      boilr
      mangohud # In-game FPS/performance overlay
      goverlay # GUI for MangoHud configuration
      wine-staging # Latest Wine for better compatibility
      winetricks # Wine helper scripts
      protontricks # Proton helper scripts
      sc-controller # Better controller support
    ];

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin # Community-enhanced Proton
      ];
    };

    programs.gamescope = {
      enable = true;
      capSysNice = true;
      args = [
        "--rt" # Use realtime scheduling
        "--expose-wayland" # Support Wayland apps
      ];
    };

    # GameMode for automatic performance optimization
    programs.gamemode = {
      enable = true;
      settings.general.renice = 10; # Renice games for better priority
    };
  };
}
