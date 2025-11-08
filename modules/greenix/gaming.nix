{ pkgs, lib, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      lutris
      (retroarch.override {
        cores = with libretro; [
          dolphin
        ];
      })
      boilr
    ];

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
    };

    programs.gamescope = {
      enable = true;
      capSysNice = true;
    };
  };
}
