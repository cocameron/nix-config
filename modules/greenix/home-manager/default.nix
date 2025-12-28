{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # Everforest Dark Hard palette colors
  everforestColors = [
    "#e67e80" # Red
    "#e69875" # Orange
    "#dbbc7f" # Yellow
    "#a7c080" # Green
    "#83c092" # Aqua
    "#7fbbb3" # Blue
    "#d699b6" # Purple
  ];

  # Map workspace ID to Everforest color (cycles through palette)
  workspaceIdToColor =
    id:
    let
      colorIndex = lib.mod (id - 1) (builtins.length everforestColors);
    in
    builtins.elemAt everforestColors colorIndex;

  # Script to update waybar border color based on active workspace
  updateWaybarBorder = pkgs.writeShellScript "update-waybar-border" ''
    # Get active workspace from niri
    ACTIVE_WS=$(${pkgs.niri}/bin/niri msg --json workspaces | ${pkgs.jq}/bin/jq -r '.[] | select(.is_active == true) | .id')

    if [ -z "$ACTIVE_WS" ]; then
      exit 0
    fi

    # Everforest colors array
    COLORS=("#e67e80" "#e69875" "#dbbc7f" "#a7c080" "#83c092" "#7fbbb3" "#d699b6")

    # Calculate color index (workspace ID - 1) % 7
    COLOR_INDEX=$(( ($ACTIVE_WS - 1) % 7 ))
    BORDER_COLOR="''${COLORS[$COLOR_INDEX]}"

    # Generate dynamic CSS
    CSS_FILE="$HOME/.config/waybar/dynamic-style.css"
    NEW_CSS="window#waybar {
      border-color: $BORDER_COLOR;
    }"

    # Only update and reload if the color actually changed
    if [ ! -f "$CSS_FILE" ] || [ "$(cat "$CSS_FILE")" != "$NEW_CSS" ]; then
      echo "$NEW_CSS" > "$CSS_FILE"
      pkill -SIGUSR2 waybar
    fi
  '';

  # Generate CSS rules for workspace colors (IDs 1-30)
  workspaceColorCSS = lib.concatMapStringsSep "\n" (
    id:
    let
      color = workspaceIdToColor id;
    in
    ''
      #workspaces button#niri-workspace-${toString id} {
        color: ${color};
      }
      #workspaces button#niri-workspace-${toString id}.active {
        color: ${color};
      }
    ''
  ) (lib.range 1 30);
in
{
  imports = [
    ../../common/home-manager/home.nix
    ./plasma.nix
    inputs.niri.homeModules.niri
    inputs.noctalia.homeModules.default
    # inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    # inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
  ];

  # Environment variables for 65" TV scaling
  # Wayland approach: explicit scale factors for each toolkit
  home.sessionVariables = {
    # Qt apps (Ghostty, etc.) - use 1.5x scaling
    QT_SCALE_FACTOR = "1.5";
    QT_AUTO_SCREEN_SCALE_FACTOR = "0"; # Disable auto-scaling, use explicit factor
    QT_ENABLE_HIGHDPI_SCALING = "1";

    # GTK apps (Firefox) - use 1.5x scaling
    GDK_SCALE = "1.5";
    GDK_DPI_SCALE = "0.833"; # Compensate fonts: 1.5 * 0.833 ≈ 1.25

    # Firefox - smooth scrolling
    MOZ_USE_XINPUT2 = "1";
  };
  programs.niri.settings = {
    prefer-no-csd = true;
    layout.focus-ring = {
      active.color = "#7fbbb3";
    };
    window-rules = [
      # Keep games at full opacity even when inactive
      # Add your game app-ids here (use `niri msg pick-window` to find them)
      {
        matches = [
          { app-id = "^steam_app_.*"; }  # Steam games
        ];
        opacity = 1.0;
      }
      {
        matches = [
          { app-id = "^gamescope$"; }  # Gamescope
        ];
        opacity = 1.0;
      }
      # Apply opacity to inactive windows (excluding games above)
      {
      	matches = [
	  { is-active = false; }
	];
	opacity = 0.8;
      }
      {
        geometry-corner-radius = {
	  bottom-left = 8.0;
	  bottom-right = 8.0;
	  top-left = 8.0;
	  top-right = 8.0;
	};
	clip-to-geometry = true;
      }
    ];
    outputs."HDMI-A-1" = {
      mode = {
        width = 3840;
        height = 2160;
      };
      scale = 2.0;
    };

    outputs."DP-1" = {
      mode = {
        width = 3840;
        height = 2160;
      };
      scale = 2.0;
    };
    xwayland-satellite = {
      enable = true;
      path = lib.getExe pkgs.xwayland-satellite;
    };

    binds = {
      "Mod+Q".action.close-window = { };

      "Mod+Left".action.focus-column-left = { };
      "Mod+Down".action.focus-window-down = { };
      "Mod+Up".action.focus-window-up = { };
      "Mod+Right".action.focus-column-right = { };
      "Mod+H".action.focus-column-left = { };
      "Mod+J".action.focus-window-down = { };
      "Mod+K".action.focus-window-up = { };
      "Mod+BracketLeft".action.consume-or-expel-window-left = { };
      "Mod+BracketRight".action.consume-or-expel-window-right = { };

      "Mod+Ctrl+Left".action.move-column-left = { };
      "Mod+Ctrl+Down".action.move-window-down = { };
      "Mod+Ctrl+Up".action.move-window-up = { };
      "Mod+Ctrl+Right".action.move-column-right = { };
      "Mod+Ctrl+H".action.move-column-left = { };
      "Mod+Ctrl+J".action.move-window-down = { };
      "Mod+Ctrl+K".action.move-window-up = { };
      "Mod+Ctrl+L".action.move-column-right = { };

      "Mod+Home".action.focus-column-first = { };
      "Mod+End".action.focus-column-last = { };
      "Mod+Ctrl+Home".action.move-column-to-first = { };
      "Mod+Ctrl+End".action.move-column-to-last = { };

      "Mod+Shift+Left".action.focus-monitor-left = { };
      "Mod+Shift+Down".action.focus-monitor-down = { };
      "Mod+Shift+Up".action.focus-monitor-up = { };
      "Mod+Shift+Right".action.focus-monitor-right = { };
      "Mod+Shift+H".action.focus-monitor-left = { };
      "Mod+Shift+J".action.focus-monitor-down = { };
      "Mod+Shift+K".action.focus-monitor-up = { };
      "Mod+Shift+L".action.focus-monitor-right = { };

      "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = { };
      "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = { };
      "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = { };
      "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = { };
      "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = { };
      "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = { };
      "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = { };

      "Mod+Page_Down".action.focus-workspace-down = { };
      "Mod+Page_Up".action.focus-workspace-up = { };
      "Mod+U".action.focus-workspace-down = { };
      "Mod+I".action.focus-workspace-up = { };
      "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = { };
      "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = { };
      "Mod+Ctrl+U".action.move-column-to-workspace-down = { };
      "Mod+Ctrl+I".action.move-column-to-workspace-up = { };

      "Mod+Shift+Page_Down".action.move-workspace-down = { };
      "Mod+Shift+Page_Up".action.move-workspace-up = { };
      "Mod+Shift+U".action.move-workspace-down = { };
      "Mod+Shift+I".action.move-workspace-up = { };

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;
      "Mod+Ctrl+1".action.move-column-to-workspace = 1;
      "Mod+Ctrl+2".action.move-column-to-workspace = 2;
      "Mod+Ctrl+3".action.move-column-to-workspace = 3;
      "Mod+Ctrl+4".action.move-column-to-workspace = 4;
      "Mod+Ctrl+5".action.move-column-to-workspace = 5;
      "Mod+Ctrl+6".action.move-column-to-workspace = 6;
      "Mod+Ctrl+7".action.move-column-to-workspace = 7;
      "Mod+Ctrl+8".action.move-column-to-workspace = 8;
      "Mod+Ctrl+9".action.move-column-to-workspace = 9;

      "Mod+Period".action.expel-window-from-column = { };

      "Mod+R".action.switch-preset-column-width = { };
      "Mod+F".action.maximize-column = { };
      "Mod+Shift+F".action.fullscreen-window = { };

      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";

      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";

      "Print".action.screenshot = { };
      "Ctrl+Print".action.screenshot-screen = { };
      "Alt+Print".action.screenshot-window = { };

      "Mod+Shift+E".action.quit = { };

      "Mod+Shift+P".action.power-off-monitors = { };

      "Mod+T".action.spawn = [ "ghostty" ];
      "Mod+Shift+Slash".action.show-hotkey-overlay = { };

      # Noctalia shell keybinds
      "Mod+Space".action.spawn = [
        "noctalia-shell"
        "ipc"
        "call"
        "launcher"
        "toggle"
      ];
      "Mod+S".action.spawn = [
        "noctalia-shell"
        "ipc"
        "call"
        "controlCenter"
        "toggle"
      ];
      "Mod+Comma".action.spawn = [
        "noctalia-shell"
        "ipc"
        "call"
        "settings"
        "toggle"
      ];

      # Audio controls
      "XF86AudioRaiseVolume".action.spawn = [
        "noctalia-shell"
        "ipc"
        "call"
        "volume"
        "increase"
      ];
      "XF86AudioLowerVolume".action.spawn = [
        "noctalia-shell"
        "ipc"
        "call"
        "volume"
        "decrease"
      ];
      "XF86AudioMute".action.spawn = [
        "noctalia-shell"
        "ipc"
        "call"
        "volume"
        "muteOutput"
      ];

      # Brightness controls
      "XF86MonBrightnessUp".action.spawn = [
        "noctalia-shell"
        "ipc"
        "call"
        "brightness"
        "increase"
      ];
      "XF86MonBrightnessDown".action.spawn = [
	      "noctalia-shell"
		      "ipc"
		      "call"
		      "brightness"
		      "decrease"
      ];

# Utility shortcuts
      "Mod+V".action.spawn = [
	      "noctalia-shell"
        "ipc"
        "call"
        "launcher"
        "clipboard"
      ];
      "Mod+C".action.spawn = [
        "noctalia-shell"
        "ipc"
        "call"
        "launcher"
        "calculator"
      ];
      "Mod+L".action.spawn = [
        "noctalia-shell"
        "ipc"
        "call"
        "lockScreen"
        "lock"
      ];
    };
  };

  programs.fuzzel.enable = true;

  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;
    settings = {
      # configure noctalia here; defaults will
      # be deep merged with these attributes.
      bar = {
        position = "top";
        showCapsule = false;
	floating = true;
        widgets = {
          left = [
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
	    {
	      id = "SystemMonitor";
	    }
          ];
          center = [
            {
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "none";
            }
          ];
          right = [
            {
              formatHorizontal = "HH:mm";
              formatVertical = "HH mm";
              id = "Clock";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
          ];
        };
      };
      colorSchemes.predefinedScheme = "Everforest";
      general = {
        avatarImage = "/home/drfoobar/.face";
        radiusRatio = 0.2;
      };
      location = {
        monthBeforeDay = true;
        name = "Portland, United States";
      };
      dock = {
        enabled = false;
      };
      controlCenter = {
      	cards = [
          {
	    id = "profile-card";
	    enabled = true;
	  }
	  {
	    id = "audio-card";
	    enabled = true;
	  }
	  {
	    id = "network-card";
	    enabled = false;
	  }
	];
      };
      calendar = {
        cards = [];
      };
    };
    # this may also be a string or a path to a JSON file,
    # but in this case must include *all* settings.
  };
  # Configure xdg-desktop-portal to use GTK backend for niri
  # This prevents timeout issues when multiple portal backends are installed
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      common = {
        default = [ "gtk" ];
      };
      niri = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
    };
  };

  # Enable mako notification daemon for niri/Wayland
  services.mako = {
    enable = true;
    # Default configuration - you can customize these
    settings = {
      default-timeout = 5000; # 5 seconds
      ignore-timeout = false;
      max-visible = 5;
      sort = "-time";
      layer = "overlay";
      anchor = "top-right";
      # Styling for TV viewing with larger text
      font = "sans-serif 14";
      width = 400;
      height = 150;
      margin = "20";
      padding = "15";
      border-size = 2;
      border-radius = 10;
      background-color = "#2d353bff";
      text-color = "#d3c6aaff";
      border-color = "#a7c080ff";
      progress-color = "over #7fbbb3ff";
    };
  };

  # Enable waybar (sway's status bar) for niri
  # Configuration adapted from YaLTeR's dotfiles
  programs.waybar = {
    enable = false;
    systemd.enable = true;
    settings = {
      mainbar = {
        layer = "top";
        height = 48; # Increased for TV viewing (was 32)
        margin-top = 4;
        margin-left = 4;
        margin-right = 4;
        spacing = 0;
        modules-left = [
          "network"
          "wlr/taskbar"
          "niri/workspaces"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "systemd-failed-units"
          "pulseaudio"
          "cpu"
          "memory"
        ];
        "systemd-failed-units" = {
          hide-on-ok = true;
          system = true;
          user = false;
        };

        "wlr/taskbar" = {
          format = "{icon}";
          tooltip-format = "{title} | {app_id}";
          on-click = "activate";
          on-click-middle = "close";
          on-click-right = "fullscreen";
        };

        "niri/workspaces" = {
          format = "{icon}";
          format-icons = {
            default = "";
            active = "";
          };
        };

        clock = {
          tooltip-format = "<small>{calendar}</small>";
          format = " {:%B %e %H:%M}";
        };

        cpu = {
          format = " {usage}%";
          tooltip = false;
        };

        memory = {
          format = " {}%";
        };

        network = {
          tooltip-format = "{ifname} via {gwaddr}";
          format = "";
          format-disconnected = "󰈂";
        };

        pulseaudio = {
          format = "{volume}% {icon}";
          format-bluetooth = "{volume}% {icon}";
          format-bluetooth-muted = " {icon}";
          format-muted = "";
          format-source = "{volume}% ";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
          };
          on-click = "pavucontrol";
        };

        tray = {
          spacing = 10;
        };
      };
    };
    style = ''
      * {
        font-family: "NotoSans Nerd Font", sans-serif;
        font-size: 16px;
        font-feature-settings: "tnum";
      }

      /* Waybar window styling with rounded corners */
      window#waybar {
        background-color: rgba(45, 53, 59, 0.95);
        border: 3px solid #a7c080;  /* Default color, overridden by dynamic CSS */
        border-radius: 15px;
      }

      /* Ensure modules have proper styling */
      .modules-left, .modules-center, .modules-right {
        background-color: transparent;
        padding: 0 10px;
      }

      /* Workspace colors - deterministically generated from IDs */
      ${workspaceColorCSS}

      /* Dynamic border color - imported from file generated by on-update script */
      @import url("file:///home/colin/.config/waybar/dynamic-style.css");
    '';
  };

  # Enable swaybg for wallpaper management
  home.packages = with pkgs; [
    swaybg
  ];

  gtk = {
    enable = true;
    font.name = "Noto Sans";
  };

  systemd.user.services.init-display-mode = {
    Unit = {
      Description = "Initialize display to safe mode";
      Before = "gamescope-session.service";
    };
    Install = {
      WantedBy = [ "gamescope-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "init-display" ''
        sleep 5
        ${pkgs.libdrm}/bin/modetest -M amdgpu -s 127:1920x1080@60 || true
      ''}";
    };
  };

  # Override noctalia-shell service to configure Qt for Wayland and bind to niri
  # Noctalia-shell is a desktop shell that runs on top of niri (the compositor)
  # It needs QT_QPA_PLATFORM=wayland to use Qt's Wayland platform plugin
  # By binding to niri.service, it only starts with niri, not other Wayland sessions
  systemd.user.services.noctalia-shell = {
    Unit = {
      # Ensure noctalia-shell starts after niri has created the Wayland socket
      After = [ "niri.service" ];
      Requisite = [ "niri.service" ];
    };
    Service = {
      Environment = [ "QT_QPA_PLATFORM=wayland" ];
    };
    Install = {
      # Override upstream WantedBy to bind to niri only, not all graphical sessions
      WantedBy = lib.mkForce [ "niri.service" ];
    };
  };

  # In configuration.nix or a system-level module
  # Start swaybg with wallpaper on login (niri only)
  # Based on niri documentation: https://github.com/YaLTeR/niri/wiki/Example-systemd-Setup
  systemd.user.services.swaybg = {
    Unit = {
      Description = "Wayland wallpaper daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
      # Bind to niri session only
      Wants = [ "niri.service" ];
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -m fill -i /home/colin/Pictures/wallpaper.png";
      Restart = "on-failure";
    };
    Install = {
      # Equivalent to: systemctl --user add-wants niri.service swaybg.service
      WantedBy = [ "niri.service" ];
    };
  };

  # Override waybar to start with niri only (instead of all graphical sessions)
  # systemd.user.services.waybar.Install.WantedBy = lib.mkForce [ "niri.service" ];

  # Initialize dynamic waybar CSS file (will be updated by on-update script)
  # home.file.".config/waybar/dynamic-style.css" = {
  #   text = ''
  #     window#waybar {
  #       border-color: #a7c080;
  #     }
  #   '';
  #   force = true;  # Allow script to modify this file
  # };

  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    systemd.enable = true;
    settings = {
      theme = "Everforest Dark Hard";
      clipboard-read = "allow";
      clipboard-write = "allow";
      # Larger font for TV viewing (default is 12)
      font-size = 16;
      font-family = "IosevkaTermSlab Nerd Font";
      gtk-titlebar = false;
      #background-opacity = 0.75;
    };
  };
}
