{ config, lib, pkgs, ... }:

let
  # Automatically provision all JSON dashboards from the dashboards directory
  dashboardFiles = builtins.readDir ./dashboards;
  dashboardEtc = lib.mapAttrs' (name: type:
    lib.nameValuePair
      "grafana/provisioning/dashboards/${name}"
      { source = ./dashboards/${name}; }
  ) (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".json" name) dashboardFiles);
in
{
  # Grafana for dashboards
  services.grafana = {
    enable = true;

    # Install VictoriaMetrics plugins
    # Note: When declarativePlugins is set, Grafana tries to install built-in plugins
    # like exploretraces, metricsdrilldown, etc., but fails due to read-only filesystem.
    # We need to include all required plugins here.
    declarativePlugins = with pkgs.grafanaPlugins; [
      victoriametrics-logs-datasource
      victoriametrics-metrics-datasource
      grafana-exploretraces-app
      grafana-lokiexplore-app
      grafana-metricsdrilldown-app
      grafana-pyroscope-app
    ];

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        domain = "grafana.nixlab.brucebrus.org";
        root_url = "https://grafana.nixlab.brucebrus.org";
      };
      security = {
        admin_user = "admin";
        admin_password = "$__file{${config.sops.secrets.grafana_admin_password.path}}";
        secret_key = "$__file{${config.sops.secrets.grafana_secret_key.path}}";
      };
      database = {
        type = "sqlite3";
        path = "/var/lib/grafana/grafana.db";
      };
      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };
      users = {
        allow_sign_up = false;
        auto_assign_org = true;
        auto_assign_org_role = "Viewer";
      };
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "VictoriaMetrics";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:8428";
          isDefault = true;
          uid = "victoriametrics";  # Changed to lowercase to avoid conflicts
        }
        {
          name = "VictoriaLogs";
          type = "victoriametrics-logs-datasource";
          access = "proxy";
          url = "http://127.0.0.1:9428";
          uid = "victorialogs";  # Changed to lowercase to avoid conflicts
        }
      ];
      dashboards = {
        settings = {
          providers = [
            {
              name = "nixlab";
              type = "file";
              options = {
                path = "/etc/grafana/provisioning/dashboards";
              };
            }
          ];
        };
      };
      alerting.rules.settings.groups = [
        {
          name = "nixlab-alerts";
          folder = "nixlab";
          interval = "1m";
          rules = [
            {
              uid = "disk-space-critical";
              title = "Disk Space Critical";
              condition = "A";
              data = [
                {
                  refId = "A";
                  datasourceUid = "victoriametrics";
                  queryType = "";
                  relativeTimeRange = {
                    from = 300;
                    to = 0;
                  };
                  datasource = {
                    type = "prometheus";
                    uid = "victoriametrics";
                  };
                  model = {
                    expr = "(1 - (node_filesystem_avail_bytes{instance=\"nixlab\",mountpoint=\"/\"} / node_filesystem_size_bytes{instance=\"nixlab\",mountpoint=\"/\"})) * 100 > 90";
                    refId = "A";
                  };
                }
              ];
              noDataState = "NoData";
              execErrState = "Alerting";
              for_ = "2m";
              annotations = {
                summary = "Critical disk space on nixlab";
                description = "Root filesystem usage is above 90%";
              };
              labels = {
                severity = "critical";
              };
            }
            {
              uid = "service-down";
              title = "Service Down";
              condition = "A";
              data = [
                {
                  refId = "A";
                  datasourceUid = "victoriametrics";
                  queryType = "";
                  relativeTimeRange = {
                    from = 300;
                    to = 0;
                  };
                  datasource = {
                    type = "prometheus";
                    uid = "victoriametrics";
                  };
                  model = {
                    expr = "caddy_reverse_proxy_upstreams_healthy == 0";
                    refId = "A";
                  };
                }
              ];
              noDataState = "NoData";
              execErrState = "Alerting";
              for_ = "1m";
              annotations = {
                summary = "Service is down";
                description = "A service monitored by Caddy reverse proxy is down";
              };
              labels = {
                severity = "critical";
              };
            }
          ];
        }
      ];
    };
  };

  # Automatically provision all JSON dashboard files from dashboards directory
  environment.etc = dashboardEtc;
}
