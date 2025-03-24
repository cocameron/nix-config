{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModule

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  home = {
    username = "colin";
    packages = with pkgs; [
      devenv
      ffmpeg
      xh
      graphviz
      imagemagick
      libxml2
      tectonic
      nodejs_23
      fzf
      ghostscript
    ]
    ++ lib.optionals stdenv.isDarwin [
    ]
    ++ lib.optionals stdenv.isLinux [
      _1password-cli
    ];
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

      userName = "Colin Cameron";
      userEmail = "me@ccameron.net";

      signing = {
        key = "08F3DF9DA5BD0D49E1B051FDBFC758DC84917FF4";
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
        default-key = "08F3DF9DA5BD0D49E1B051FDBFC758DC84917FF4";
      };
    };
  };

  services = {
    gpg-agent = {
      enable = true;
      enableZshIntegration = true;
      extraConfig = ''
        # Use the system-wide pinentry path
        pinentry-program /run/current-system/sw/bin/pinentry
      '';
    };
  };
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";
}
