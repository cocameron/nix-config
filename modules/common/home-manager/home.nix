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
  config = {
    home = {
      username = "colin";
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
          claude-code
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
            name = "Colin Cameron";
            email = "me@ccameron.net";
          };
        };

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

      podman = {
        enable = true;
        containers = {
	  gluetun = {
	    image = "qmcgaw/gluetun";
	    addCapabilities = ["NET_ADMIN"];
	    devices = ["/dev/net/tun:/dev/net/tun"];
	    volumes = [
	      "/home/colin/.local/config/gluetun:/config"
	    ];
	    ports = [
	     "8888:8888/tcp"  # Gluetun Local Network HTTP proxy                     
	     "8388:8388/tcp"  # Gluetun Local Network Shadowsocks                     
	     "8388:8388/udp"  # Gluetun Local Network Shadowsocks 
	     "8200:8200" # qbit web ui
	    ];
	    environmentFile = ["/home/colin/code/nix-config/.env"];
	    environment = {
	      WIREGUARD_MTU=1320;
	      TZ = "America/Los_Angeles";
	      VPN_SERVICE_PROVIDER="protonvpn";
	      VPN_TYPE="wireguard";
	      PORT_FORWARD_ONLY="on";
	      VPN_PORT_FORWARDING="on";
	      VPN_PORT_FORWARDING_UP_COMMAND = "\\\"/bin/sh -c '/config/assign-ports.sh qbit {{PORTS}}'\\\"";
	      HTTPPROXY="on";
	      SHADOWSOCKS="on";
	    };
	  };
	  qbittorrent = {
	    image="qbittorrentofficial/qbittorrent-nox";
	    volumes= [
	     "/home/colin/.config/qbittorrent:/config"
	     "/mnt/nfs/content:/data"
	    ];
	    extraConfig = {
		Unit.Requires = "podman-gluetun.service";
		Unit.After = "podman-gluetun.service";
	    };
	    network = lib.mkForce ["container:gluetun"];
	    environment = {
	      TZ = "America/Los_Angeles";
	      QBT_LEGAL_NOTICE="confirm";
	      QBT_VERSION="latest";
	      QBT_WEBUI_PORT=8200;
	      QBT_CONFIG_PATH="/config";
	      QBT_DOWNLOADS_PATH="/downloads";
	    };
	  };
        };
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
