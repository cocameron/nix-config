{ config, pkgs, ... }:

{
  power.ups = {
    enable = true;
    mode = "standalone";

    # Declare your USB-connected UPS
    ups."main" = {
      description = "Main UPS";
      driver = "usbhid-ups";
      port = "auto";
      directives = [
        "offdelay = 60"    # Wait 60 seconds before turning off UPS
        "ondelay = 70"     # Wait 70 seconds before turning UPS back on
        "lowbatt = 40"     # Consider battery low at 40%
        "ignorelb"         # Ignore low battery flag from UPS, use lowbatt threshold
      ];
    };

    # Configure upsd to listen on localhost
    upsd.listen = [
      { address = "127.0.0.1"; port = 3493; }
      { address = "::1"; port = 3493; }
    ];

    # Create monitoring user
    users."upsmon" = {
      passwordFile = config.sops.secrets.upsmon_pass.path;
      upsmon = "primary";
    };

    # Monitor the UPS
    upsmon.monitor."main" = {
      system = "main@localhost";
      powerValue = 1;
      user = "upsmon";
      passwordFile = config.sops.secrets.upsmon_pass.path;
      type = "primary";
    };
  };
}
