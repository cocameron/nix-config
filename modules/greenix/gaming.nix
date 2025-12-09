{ pkgs, lib, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      lutris
      (retroarch.withCores (
        cores: with cores; [
          dolphin
          mgba      # Game Boy Advance
          gambatte  # Game Boy / Game Boy Color
	  pcsx2
        ]
      ))
      boilr
      mangohud # In-game FPS/performance overlay
      goverlay # GUI for MangoHud configuration
      wineWowPackages.staging # Wine with full 32-bit and 64-bit support
      winetricks # Wine helper scripts
      protontricks # Proton helper scripts
      sc-controller # Better controller support
      sunshine # Game streaming server
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
      # Force Steam to use XWayland for proper window decorations
      package = pkgs.steam.override {
        extraArgs = "-steamos3";
      };
    };

    # Gamescope is now managed by Jovian NixOS
    # Keep this enabled for compatibility but Jovian will provide optimized settings
    programs.gamescope.enable = true;

    # GameMode for automatic performance optimization
    programs.gamemode = {
      enable = true;
      settings.general.renice = 10; # Renice games for better priority
    };

    # Sunshine for game streaming (GPU-accelerated)
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true; # Required for better performance
      openFirewall = true; # Opens ports 47984-48010
    };

    # Add user to required groups for Sunshine GPU access
    users.users.colin.extraGroups = [
      "video"
      "render"
      "input"
    ];

    # Udev rules for DualSense controller access in Sunshine
    services.udev.extraRules = ''
      # Sony DualSense controllers
      KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0660", TAG+="uaccess"
    '';
  };
}
