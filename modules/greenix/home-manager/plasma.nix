{ ... }:
{
  programs.plasma = {
    enable = true;

    # Workspace configuration
    workspace = {
      cursor = {
        theme = "breeze_cursors";
        size = 32;
      };
    };

    # Fonts - much larger sizes for 65" TV viewing from distance
    fonts = {
      general = {
        family = "Noto Sans";
        pointSize = 13;
      };
      fixedWidth = {
        family = "Hack";
        pointSize = 13;
      };
      small = {
        family = "Noto Sans";
        pointSize = 11;
      };
      toolbar = {
        family = "Noto Sans";
        pointSize = 13;
      };
      menu = {
        family = "Noto Sans";
        pointSize = 13;
      };
      windowTitle = {
        family = "Noto Sans";
        pointSize = 16;
      };
    };

    # Window management - easier to see and use from distance
    kwin = {
      titlebarButtons = {
        left = [ "close" ];
        right = [
          "minimize"
          "maximize"
        ];
      };
    };

    # Panels configuration
    panels = [
      {
        location = "bottom";
        height = 48; # Balanced panel height for TV viewing
        widgets = [
          {
            kickoff = {
              icon = "nix-snowflake";
            };
          }
          {
            iconTasks = {
              launchers = [ ];
            };
          }
          {
            name = "org.kde.plasma.marginsseparator";
          }
          "org.kde.plasma.systemtray"
          {
            digitalClock = {
              time = {
                format = "24h";
                showSeconds = "never";
              };
              date = {
                enable = true;
                format = "shortDate";
                position = "besideTime";
              };
            };
          }
        ];
      }
    ];

    # Shortcuts - useful for controller mapping with antimicrox
    shortcuts = {
      kwin = {
        # Easy window switching
        "Walk Through Windows" = "Meta+Tab";
        "Walk Through Windows (Reverse)" = "Meta+Shift+Tab";
        # Fullscreen toggle
        "Window Fullscreen" = "Meta+F";
        # Virtual desktop navigation (useful with controller)
        "Switch to Next Desktop" = "Meta+Right";
        "Switch to Previous Desktop" = "Meta+Left";
      };
      # Application launcher
      "org.kde.plasma.emojier.desktop" = {
        _launch = [ ];
      };
      plasmashell = {
        "activate application launcher" = [
          "Meta"
          "Alt+F1"
        ];
      };
    };

    # Appearance settings
    configFile = {
      # Normal icon sizes
      "dolphinrc"."IconsMode"."IconSize" = 64;
      "dolphinrc"."DetailsMode"."IconSize" = 22;

      # Kickoff (application menu) settings
      "kickoffrc"."General"."UseExtraRunners" = false;

      # KRunner settings - larger font and results
      "krunnerrc"."General" = {
        FreeFloating = true;
      };

      # Window decoration settings - larger borders for TV viewing
      "kwinrc"."org.kde.kdecoration2" = {
        BorderSize = "Large";
        BorderSizeAuto = false;
      };

      # Desktop effects - add helpful zoom for accessibility
      "kwinrc"."Effect-zoom" = {
        InitialZoom = 1;
      };

      # Better defaults for viewing from distance
      "kdeglobals"."KDE" = {
        AnimationDurationFactor = 0.5; # Slightly faster animations
        SingleClick = false; # Double-click is more TV-friendly
      };

      # File dialog settings - larger previews
      "kdeglobals"."KFileDialog Settings" = {
        "Show Preview" = true;
        "Preview Width" = 320;
      };

      # Wayland scaling for 65" TV - use 1.5x global scale
      "kdeglobals"."KScreen" = {
        ScaleFactor = 1.5;
      };

      # Font DPI for consistent rendering
      "kcmfonts"."General" = {
        forceFontDPI = 144; # 1.5x DPI scaling (144/96 = 1.5)
      };
    };
  };
}
