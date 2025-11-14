{
  inputs,
  lib,
  config,
  pkgs,
  pkgs-unstable ? pkgs,
  ...
}:
let
  constants = import ../constants.nix;
in
{
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModule

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
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
        ]
        ++ config.local.machinePackages;
      sessionVariables = {
        GPG_TTY = "$(tty)";
      };
    };

    programs = {
      home-manager.enable = true;
      neovim.enable = true;
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
      bottom.enable = true;
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
      };
      starship = {
        enable = true;
        enableZshIntegration = true;
      };
      ripgrep.enable = true;
      fd.enable = true;
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
          		pinentry-program /run/current-system/sw/bin/${if pkgs.stdenv.isDarwin then "pinentry-mac" else "pinentry"}
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
