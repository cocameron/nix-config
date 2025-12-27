{
  lib,
  config,
  pkgs,
  ...
}:

{
  services.home-assistant = {
    enable = true;

    customComponents = [
      pkgs.home-assistant-custom-components.emporia_vue
    ];

    extraComponents = [
      "esphome"
      "met"
      "radio_browser"
      "simplisafe"
      "spotify"
      "apple_tv"
      "androidtv_remote"
      "google_translate"
      "cast"
      "hue"
      "sonos"
      "plex"
      "music_assistant"
      "homekit_controller"
      "ecobee"
      "isal"
      "zha"
      "zwave_js"
      "hassio"
      "homekit"
      "wemo"
      "wiz"
    ];

    config = {
      default_config = { };
      automation = "!include automations.yaml";
      scene = "!include scenes.yaml";
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "::1"
          "127.0.0.1"
        ];
      };
      zha = {
        usb_path = "/dev/ttyUSB0";
      };
      wemo = {
        discovery = false;
        static = [
          "192.168.1.185"
          "192.168.1.167"
        ];
      };
    };
  };

  # Z-Wave JS UI
  services.zwave-js-ui = {
    enable = true;
    serialPort = "/dev/serial/by-id/usb-Nabu_Casa_ZWA-2_80B54EE6BA98-if00";
    settings = {
      PORT = "8092";
    };
  };

  # Fix firmware update fetching by providing DNS and SSL certificates to the chroot
  systemd.services.zwave-js-ui.serviceConfig.BindReadOnlyPaths = [
    "/etc/resolv.conf"
    "/etc/ssl/certs"
    "/etc/static/ssl/certs"
  ];

  # Firewall configuration for HomeKit bridge
  networking.firewall = {
    allowedTCPPorts = [ 21064 ];
    allowedUDPPorts = [ 5353 ];
  };
}
