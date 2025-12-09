{ pkgs, lib, ... }:
let
  sddmTheme = pkgs.stdenv.mkDerivation {
    name = "sddm-session-grid-theme";
    src = ./sddm-session-grid-theme;
    installPhase = ''
      mkdir -p $out/share/sddm/themes/session-grid
      cp -r * $out/share/sddm/themes/session-grid/
    '';
  };
in
{
  config = {
    # Resolve conflict between GNOME and KDE SSH askPassword
    programs.ssh.askPassword = lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";

    # Select internationalisation properties. (time.timeZone is in base.nix)
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Use SDDM for better controller support and session selection
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      autoNumlock = true;
      # Custom session-focused theme
      theme = "session-grid";
      # Enable controller/gamepad navigation in SDDM
      settings = {
        General = {
          InputMethod = "";
          # Don't remember last session - force session selection each time
          RememberSession = "false";
        };
        Theme = {
          Current = "session-grid";
          CursorTheme = "breeze_cursors";
        };
        Users = {
          # Remember last user but not session
          RememberLastUser = "true";
        };
      };
    };

    # Clear SDDM QML cache when theme changes
    # The cache is stored in a Nix-managed directory linked to the theme derivation
    # When the theme changes, Nix creates a new path, automatically invalidating old cache
    environment.etc."sddm-theme-marker".source = pkgs.writeText "sddm-theme-version" sddmTheme.outPath;

    # Clear cache before starting SDDM, but only if theme marker changed
    systemd.services.display-manager.preStart = ''
      # If the theme marker changed, clear the cache
      if [ -f /var/lib/sddm/.theme-marker ]; then
        if ! cmp -s /etc/sddm-theme-marker /var/lib/sddm/.theme-marker; then
          echo "SDDM theme changed ($(cat /etc/sddm-theme-marker)), clearing QML cache..."
          rm -rf /var/lib/sddm/.cache/sddm-greeter-qt6
          cp /etc/sddm-theme-marker /var/lib/sddm/.theme-marker
        fi
      else
        echo "First run, clearing SDDM QML cache..."
        mkdir -p /var/lib/sddm
        rm -rf /var/lib/sddm/.cache/sddm-greeter-qt6
        cp /etc/sddm-theme-marker /var/lib/sddm/.theme-marker
      fi
    '';

    # Enable the GNOME Desktop Environment.
    services.desktopManager.gnome.enable = true;

    # Enable KDE Plasma as an alternative desktop environment
    services.desktopManager.plasma6.enable = true;

    # Enable niri as an alternative compositor
    programs.niri.enable = true;
    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };
    # DPI and Scaling - for 65" 4K TV viewing
    # Using 144 DPI (1.5x) for balanced scaling across all apps
    services.xserver.dpi = 144;
    environment.variables = {
      # Cursor size for TV (scaled for 1.5x)
      XCURSOR_SIZE = "48";
      # Java apps scaling
      _JAVA_OPTIONS = "-Dsun.java2d.uiScale=1.5";
    };
    # Note: Per-toolkit scaling (QT, GTK) is set in home-manager for per-user control

    # Disable automatic login - user will see login screen
    # services.displayManager.autoLogin.enable = true;
    # services.displayManager.autoLogin.user = "colin";

    # Allow passwordless login via SDDM
    security.pam.services.sddm.allowNullPassword = true;

    # Allow passwordless login via polkit for the user
    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
          if (subject.user == "colin") {
              return polkit.Result.YES;
          }
      });
    '';

    systemd.user.services.orca.enable = false;

    # Install firefox.
    programs.firefox.enable = true;

    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "colin" ];
    };

    # Add packages needed for desktop environment
    environment.systemPackages =
      with pkgs;
      [
        xsettingsd
        xorg.xrdb
        ulauncher
        # KDE utilities
        kdePackages.kate # Text editor
        kdePackages.konsole # Terminal
        everforest-gtk-theme
        kdePackages.sddm-kcm

        # TV-friendly additions
        antimicrox # Map gamepad to keyboard/mouse for navigation
      ]
      ++ [
        # Custom SDDM theme
        sddmTheme
      ];

    # Enable CUPS to print documents (moved from services.nix)
    services.printing.enable = true;
  };
}
