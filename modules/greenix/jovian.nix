{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = {
    # Enable Jovian's Steam Deck-like gaming experience
    jovian.steam = {
      enable = true;
      # Don't auto-start - keep SDDM and launch gaming mode manually
      autoStart = false;
      # Specify the user running Steam
      user = "colin";
      # Desktop session to switch to when exiting gaming mode
      desktopSession = "plasma";
      # Custom environment variables for gaming
      environment = {
        # AMD-specific optimizations
        # RADV is the AMD Vulkan driver (Mesa), used automatically
        # For video acceleration with AMD
        LIBVA_DRIVER_NAME = "radeonsi";
        # Enable HDR and VRR features
        DXVK_HDR = "1";
        ENABLE_VKBASALT = "1";
        # Force 120Hz refresh rate (Jovian uses STEAM_DISPLAY_REFRESH_LIMITS)
        STEAM_DISPLAY_REFRESH_LIMITS = "119,120";
        # Add system binaries to PATH for Heroic/Wine support
        PATH = "/run/current-system/sw/bin:\${PATH}";
      };
    };

    # Enable Decky Loader for Steam Deck plugins
    jovian.decky-loader = {
      enable = true;
      user = "colin";
    };

    # Enable SteamOS-like system configurations for gaming
    jovian.steamos = {
      # Use SteamOS configuration defaults where applicable
      useSteamOSConfig = true;
      # Enable zram for better memory management during gaming
      enableZram = true;
      # Enable early OOM killer to prevent system freezes
      enableEarlyOOM = true;
    };

    # Configure gamescope for 4K@120Hz
    # Override gamescope-session to use native 4K resolution
    systemd.user.services.gamescope-session = {
      serviceConfig = {
        ExecStart = lib.mkForce [
          "" # Clear the original ExecStart
          (pkgs.writeShellScript "gamescope-session-4k120" ''
            # Run gamescope-session with 4K@120Hz settings on DP-1 (TV)
            export STEAM_GAMESCOPE_WIDTH=3840
            export STEAM_GAMESCOPE_HEIGHT=2160
            export STEAM_GAMESCOPE_REFRESH=120
            # Use DP-1 (TV) for direct play. DP-1 remains active even when TV is off,
            # allowing Sunshine to capture and stream at 1080p@60 via HDMI-A-1 virtual display
            export GAMESCOPE_CONNECTOR=DP-1

            # Patch the original script to use our resolution
            ORIGINAL_SCRIPT="${pkgs.gamescope-session}/lib/steamos/gamescope-session"
            ${pkgs.gnused}/bin/sed \
              -e 's/-w [0-9]* -h [0-9]*/-w 3840 -h 2160 -W 3840 -H 2160 -r 120/g' \
              "$ORIGINAL_SCRIPT" > /tmp/gamescope-session-4k.sh

            chmod +x /tmp/gamescope-session-4k.sh
            exec /tmp/gamescope-session-4k.sh
          '')
        ];
      };
    };
  };
}
