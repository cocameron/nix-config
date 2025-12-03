{ pkgs, lib, config, ... }:
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
        # NVIDIA-specific optimizations
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        LIBVA_DRIVER_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
        # Disable hardware cursors for NVIDIA Wayland compatibility
        WLR_NO_HARDWARE_CURSORS = "1";
        # Enable HDR and VRR features
        DXVK_HDR = "1";
        ENABLE_VKBASALT = "1";
        # Force 120Hz refresh rate (Jovian uses STEAM_DISPLAY_REFRESH_LIMITS)
        STEAM_DISPLAY_REFRESH_LIMITS = "119,120";
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

    # Patch gamescope-session to force 120Hz
    # Jovian's script hardcodes refresh limits based on hardware detection
    # We override the entire script to set our own refresh rate
    systemd.user.services.gamescope-session = {
      serviceConfig = {
        ExecStart = lib.mkForce [
          "" # Clear the original ExecStart
          (pkgs.writeShellScript "gamescope-session-120hz" ''
            # Patch gamescope-session to force 120Hz on external displays
            ORIGINAL_SCRIPT="${pkgs.gamescope-session}/lib/steamos/gamescope-session"

            # Patch the script for 4K@120Hz gaming:
            # 1. Set refresh to 120Hz
            # 2. Use CVT mode generation
            # 3. Use 1920x1080 nested for better game compatibility
            # 4. Output at 3840x2160@120Hz with FSR upscaling
            # 5. Keep --xwayland-count 2 (needed for gaming mode)
            # Note: MangoHud/mangoapp cause visual corruption at 120Hz - keep disabled
            ${pkgs.gnused}/bin/sed \
              -e 's/STEAM_DISPLAY_REFRESH_LIMITS=[0-9,]*/STEAM_DISPLAY_REFRESH_LIMITS=119,120/g' \
              -e 's/--generate-drm-mode fixed/--generate-drm-mode cvt/g' \
              -e 's/-w 1280 -h 800/-w 1920 -h 1080 -W 3840 -H 2160 -r 120 -F fsr/g' \
              "$ORIGINAL_SCRIPT" > /tmp/gamescope-session-patched.sh

            # Make it executable and run it
            chmod +x /tmp/gamescope-session-patched.sh
            exec /tmp/gamescope-session-patched.sh
          '')
        ];
      };
    };
  };
}
