{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  constants = import ../constants.nix;
in
{
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModule

    # Nixvim configuration
    ./nixvim.nix
  ];
  config = {
    home = {
      username = constants.primaryUser;
      packages =
        with pkgs;
        [
          devenv
          ffmpeg
          xh
          graphviz
          imagemagick
          libxml2
          tectonic
          nodejs_24
          fzf
          ghostscript
          jq
          flac
          yq-go
          nvd
          nh
          claude-code
	  fd
	  cargo
        ]
        ++ config.local.machinePackages;
      sessionVariables = {
        GPG_TTY = "$(tty)";
      };
    };


    programs = {
      home-manager.enable = true;
      git = {
        enable = true;
        lfs.enable = true;
        settings = {
          user = {
            name = constants.git.userName;
            email = constants.git.userEmail;
          };
        };

        signing = {
          key = constants.gpgKey;
          signByDefault = true;
        };
      };
      bottom = {
        enable = true;
        settings = {
          # Everforest Dark color scheme
          colors = {
            table_header_color = "#a7c080";
            all_cpu_color = "#7fbbb3";
            avg_cpu_color = "#83c092";
            cpu_core_colors = [
              "#e67e80"
              "#e69875"
              "#dbbc7f"
              "#a7c080"
              "#83c092"
              "#7fbbb3"
              "#d699b6"
            ];
            ram_color = "#a7c080";
            swap_color = "#e69875";
            rx_color = "#a7c080";
            tx_color = "#e67e80";
            rx_total_color = "#83c092";
            tx_total_color = "#e69875";
            border_color = "#859289";
            highlighted_border_color = "#a7c080";
            text_color = "#d3c6aa";
            selected_text_color = "#2b3339";
            selected_bg_color = "#a7c080";
            widget_title_color = "#d3c6aa";
            graph_color = "#859289";
            high_battery_color = "#a7c080";
            medium_battery_color = "#dbbc7f";
            low_battery_color = "#e67e80";
          };
          flags = {
            color = "default";
            rate = 1000;
            default_time_value = 60000;
            time_delta = 15000;
          };
        };
      };
      atuin = {
        enable = true;
        enableZshIntegration = true;
      };
      zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        shellAliases = {
          ll = "ls -l";
          vim = "nvim";
        };
        history.size = 10000;
        initContent = ''
          # Start in ~/code/nix-config when logging in
          if [[ "$PWD" == "$HOME" ]]; then
            cd ~/code/nix-config
          fi
        '';
      };
      starship = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          # Pure preset format with Everforest colors
          format = lib.concatStrings [
            "$username"
            "$hostname"
            "$directory"
            "$git_branch"
            "$git_state"
            "$git_status"
            "$cmd_duration"
            "$line_break"
            "$python"
            "$character"
          ];

          directory = {
            style = "#7fbbb3"; # Everforest blue
          };

          character = {
            success_symbol = "[❯](#d699b6)"; # Everforest purple
            error_symbol = "[❯](#e67e80)"; # Everforest red
            vimcmd_symbol = "[❮](#a7c080)"; # Everforest green
          };

          git_branch = {
            format = "[$branch]($style)";
            style = "#859289"; # Everforest grey1
          };

          git_status = {
            format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](#e69875) ($ahead_behind$stashed)]($style)";
            style = "#83c092"; # Everforest aqua
            conflicted = "​";
            untracked = "​";
            modified = "​";
            staged = "​";
            renamed = "​";
            deleted = "​";
            stashed = "≡";
          };

          git_state = {
            format = ''\([$state( $progress_current/$progress_total)]($style)\) '';
            style = "#859289"; # Everforest grey1
          };

          cmd_duration = {
            format = "[$duration]($style) ";
            style = "#dbbc7f"; # Everforest yellow
          };

          python = {
            format = "[$virtualenv]($style) ";
            style = "#859289"; # Everforest grey1
            detect_extensions = [ ];
            detect_files = [ ];
          };
        };
      };
      ripgrep.enable = true;
      fd.enable = true;
      bat = {
        enable = true;
        config = {
          theme = "ansi";
          style = "numbers,changes,header";
        };
      };
      yt-dlp.enable = true;
      navi.enable = true;
      gpg = {
        enable = true;
        settings = {
          no-greeting = true;
          default-key = constants.gpgKey;
        };
      };
    };

    services = {
      gpg-agent = {
        enable = true;
        enableZshIntegration = true;
        extraConfig = ''
          		# Use the system-wide pinentry path
          		pinentry-program /run/current-system/sw/bin/${
              if pkgs.stdenv.isDarwin then "pinentry-mac" else "pinentry"
            }
          	      '';
      };
    };
    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "24.11";
  };
  options.local.machinePackages = lib.mkOption {
    default = [ ];
    type = lib.types.listOf lib.types.package;
  };

}
