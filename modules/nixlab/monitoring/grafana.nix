{ config, lib, pkgs, ... }:

let
  # Get memory limits from system-resources module
  memLimits = config.nixlab.memoryLimits;

  # Generate system overview dashboard with memory limits
  systemOverviewDashboard = pkgs.writeText "system-overview.json"
    (import ./dashboards/system-overview.nix { memoryLimits = memLimits; });

  # Automatically provision other JSON dashboards from the dashboards directory
  dashboardFiles = builtins.readDir ./dashboards;
  otherDashboards = lib.mapAttrs' (name: type:
    lib.nameValuePair
      "grafana/provisioning/dashboards/${name}"
      { source = ./dashboards/${name}; }
  ) (lib.filterAttrs (name: type:
      type == "regular" &&
      lib.hasSuffix ".json" name &&
      name != "system-overview.json"
    ) dashboardFiles);

  # Combine generated and static dashboards
  dashboardEtc = otherDashboards // {
    "grafana/provisioning/dashboards/system-overview.json" = {
      source = systemOverviewDashboard;
    };
  };
in
{
  # Grafana for dashboards
  services.grafana = {
    enable = true;

    # Install VictoriaMetrics plugins only
    declarativePlugins = with pkgs.grafanaPlugins; [
      victoriametrics-logs-datasource
      victoriametrics-metrics-datasource
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
        allow_embedding = true;
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
            {
              uid = "memory-critical";
              title = "Memory Usage Critical";
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
                    expr = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90";
                    refId = "A";
                  };
                }
              ];
              noDataState = "NoData";
              execErrState = "Alerting";
              for_ = "5m";
              annotations = {
                summary = "Memory usage critical on nixlab";
                description = "Memory usage is above 90% for 5 minutes";
              };
              labels = {
                severity = "critical";
              };
            }
            {
              uid = "memory-warning";
              title = "Memory Usage Warning";
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
                    expr = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80";
                    refId = "A";
                  };
                }
              ];
              noDataState = "NoData";
              execErrState = "Alerting";
              for_ = "10m";
              annotations = {
                summary = "Memory usage warning on nixlab";
                description = "Memory usage is above 80% for 10 minutes";
              };
              labels = {
                severity = "warning";
              };
            }
            {
              uid = "cpu-high";
              title = "CPU Usage High";
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
                    expr = "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > 80";
                    refId = "A";
                  };
                }
              ];
              noDataState = "NoData";
              execErrState = "Alerting";
              for_ = "10m";
              annotations = {
                summary = "CPU usage high on nixlab";
                description = "CPU usage is above 80% for 10 minutes";
              };
              labels = {
                severity = "warning";
              };
            }
            {
              uid = "nfs-mount-unavailable";
              title = "NFS Mount Unavailable";
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
                    expr = "absent(node_filesystem_avail_bytes{mountpoint=\"/mnt/nfs\"})";
                    refId = "A";
                  };
                }
              ];
              noDataState = "OK";
              execErrState = "Alerting";
              for_ = "2m";
              annotations = {
                summary = "NFS mount unavailable on nixlab";
                description = "The NFS mount at /mnt/nfs is not available";
              };
              labels = {
                severity = "critical";
              };
            }
            {
              uid = "service-crash-loop";
              title = "Service Crash Loop Detected";
              condition = "A";
              data = [
                {
                  refId = "A";
                  datasourceUid = "victoriametrics";
                  queryType = "";
                  relativeTimeRange = {
                    from = 900;
                    to = 0;
                  };
                  datasource = {
                    type = "prometheus";
                    uid = "victoriametrics";
                  };
                  model = {
                    expr = "rate(node_systemd_unit_state{state=\"failed\"}[15m]) > 0";
                    refId = "A";
                  };
                }
              ];
              noDataState = "NoData";
              execErrState = "Alerting";
              for_ = "5m";
              annotations = {
                summary = "Service crash loop detected on nixlab";
                description = "A systemd service is repeatedly failing";
              };
              labels = {
                severity = "critical";
              };
            }
            {
              uid = "systemd-service-failed";
              title = "Systemd Service Failed";
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
                    expr = "node_systemd_unit_state{state=\"failed\"} == 1";
                    refId = "A";
                  };
                }
              ];
              noDataState = "NoData";
              execErrState = "Alerting";
              for_ = "2m";
              annotations = {
                summary = "Systemd service failed on nixlab";
                description = "A systemd service is in failed state";
              };
              labels = {
                severity = "warning";
              };
            }
            {
              uid = "load-average-high";
              title = "Load Average High";
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
                    expr = "node_load15 / count(node_cpu_seconds_total{mode=\"idle\"}) > 2";
                    refId = "A";
                  };
                }
              ];
              noDataState = "NoData";
              execErrState = "Alerting";
              for_ = "15m";
              annotations = {
                summary = "Load average high on nixlab";
                description = "15-minute load average is more than 2x the CPU count";
              };
              labels = {
                severity = "warning";
              };
            }
            {
              uid = "system-temperature-high";
              title = "System Temperature High";
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
                    expr = "node_hwmon_temp_celsius > 80";
                    refId = "A";
                  };
                }
              ];
              noDataState = "NoData";
              execErrState = "OK";
              for_ = "5m";
              annotations = {
                summary = "System temperature high on nixlab";
                description = "System temperature is above 80°C";
              };
              labels = {
                severity = "warning";
              };
            }
            {
              uid = "qbittorrent-exporter-down";
              title = "qBittorrent Exporter Down";
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
                    expr = "up{job=\"qbittorrent\"} == 0";
                    refId = "A";
                  };
                }
              ];
              noDataState = "OK";
              execErrState = "Alerting";
              for_ = "3m";
              annotations = {
                summary = "qBittorrent exporter down on nixlab";
                description = "Unable to scrape qBittorrent metrics";
              };
              labels = {
                severity = "warning";
              };
            }
            {
              uid = "disk-io-saturation";
              title = "Disk I/O Saturation";
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
                    expr = "rate(node_disk_io_time_seconds_total[5m]) > 0.9";
                    refId = "A";
                  };
                }
              ];
              noDataState = "NoData";
              execErrState = "Alerting";
              for_ = "10m";
              annotations = {
                summary = "Disk I/O saturation on nixlab";
                description = "Disk I/O utilization is above 90% for 10 minutes";
              };
              labels = {
                severity = "warning";
              };
            }
            {
              uid = "network-errors-high";
              title = "Network Errors High";
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
                    expr = "rate(node_network_receive_errs_total[5m]) > 10 or rate(node_network_transmit_errs_total[5m]) > 10";
                    refId = "A";
                  };
                }
              ];
              noDataState = "NoData";
              execErrState = "Alerting";
              for_ = "5m";
              annotations = {
                summary = "Network errors high on nixlab";
                description = "Network interface is experiencing high error rates";
              };
              labels = {
                severity = "warning";
              };
            }
            {
              uid = "slice-memory-throttling";
              title = "Systemd Slice Memory Throttling";
              condition = "C";
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
                    expr = ''
                      (sum(cgroup_memory_current_bytes{instance="nixlab",cgroup=~"network\\.slice/.*"}) / (${toString memLimits.network.max} * 1024 * 1024)) > 0.80 or
                      (sum(cgroup_memory_current_bytes{instance="nixlab",cgroup=~"monitoring\\.slice/.*"}) / (${toString memLimits.monitoring.max} * 1024 * 1024)) > 0.80 or
                      (sum(cgroup_memory_current_bytes{instance="nixlab",cgroup=~"media\\.slice/.*"}) / (${toString memLimits.mediaSystem.max} * 1024 * 1024)) > 0.80 or
                      (sum(cgroup_memory_current_bytes{instance="nixlab",cgroup=~"user\\.slice/user-1000\\.slice/user@1000\\.service/media\\.slice/.*"}) / (${toString memLimits.mediaUser.max} * 1024 * 1024)) > 0.80
                    '';
                    refId = "A";
                  };
                }
                {
                  refId = "B";
                  datasourceUid = "-100";
                  queryType = "";
                  relativeTimeRange = {
                    from = 0;
                    to = 0;
                  };
                  model = {
                    expression = "A";
                    reducer = "max";
                    settings = {
                      mode = "dropNN";
                    };
                    type = "reduce";
                  };
                }
                {
                  refId = "C";
                  datasourceUid = "-100";
                  queryType = "";
                  relativeTimeRange = {
                    from = 0;
                    to = 0;
                  };
                  model = {
                    conditions = [
                      {
                        evaluator = {
                          params = [ 0 ];
                          type = "gt";
                        };
                        query = {
                          params = [ "B" ];
                        };
                        type = "query";
                      }
                    ];
                    expression = "B";
                    type = "threshold";
                  };
                }
              ];
              noDataState = "NoData";
              execErrState = "Alerting";
              for_ = "3m";
              annotations = {
                summary = "Systemd slice approaching MemoryMax threshold";
                description = "A systemd slice is at {{ $value | humanizePercentage }} of its MemoryMax limit and will be throttled soon";
              };
              labels = {
                severity = "warning";
              };
            }
            {
              uid = "slice-memory-critical";
              title = "Systemd Slice Memory Critical";
              condition = "C";
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
                    expr = ''
                      (sum(cgroup_memory_current_bytes{instance="nixlab",cgroup=~"network\\.slice/.*"}) / (${toString memLimits.network.max} * 1024 * 1024)) > 0.90 or
                      (sum(cgroup_memory_current_bytes{instance="nixlab",cgroup=~"monitoring\\.slice/.*"}) / (${toString memLimits.monitoring.max} * 1024 * 1024)) > 0.90 or
                      (sum(cgroup_memory_current_bytes{instance="nixlab",cgroup=~"media\\.slice/.*"}) / (${toString memLimits.mediaSystem.max} * 1024 * 1024)) > 0.90 or
                      (sum(cgroup_memory_current_bytes{instance="nixlab",cgroup=~"user\\.slice/user-1000\\.slice/user@1000\\.service/media\\.slice/.*"}) / (${toString memLimits.mediaUser.max} * 1024 * 1024)) > 0.90
                    '';
                    refId = "A";
                  };
                }
                {
                  refId = "B";
                  datasourceUid = "-100";
                  queryType = "";
                  relativeTimeRange = {
                    from = 0;
                    to = 0;
                  };
                  model = {
                    expression = "A";
                    reducer = "max";
                    settings = {
                      mode = "dropNN";
                    };
                    type = "reduce";
                  };
                }
                {
                  refId = "C";
                  datasourceUid = "-100";
                  queryType = "";
                  relativeTimeRange = {
                    from = 0;
                    to = 0;
                  };
                  model = {
                    conditions = [
                      {
                        evaluator = {
                          params = [ 0 ];
                          type = "gt";
                        };
                        query = {
                          params = [ "B" ];
                        };
                        type = "query";
                      }
                    ];
                    expression = "B";
                    type = "threshold";
                  };
                }
              ];
              noDataState = "NoData";
              execErrState = "Alerting";
              for_ = "2m";
              annotations = {
                summary = "Systemd slice near MemoryMax limit - OOM imminent";
                description = "A systemd slice is at {{ $value | humanizePercentage }} of its MemoryMax limit. Services may be killed by systemd-oomd.";
              };
              labels = {
                severity = "critical";
              };
            }
            {
              uid = "oom-kills-detected";
              title = "OOM Kills Detected";
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
                    expr = "sum(increase(cgroup_memory_events_oom_kill_total{instance=\"nixlab\"}[5m])) > 0";
                    refId = "A";
                  };
                }
              ];
              noDataState = "NoData";
              execErrState = "OK";
              for_ = "1m";
              annotations = {
                summary = "OOM killer invoked on nixlab";
                description = "{{ $value }} processes were killed by the OOM killer in the last 5 minutes. Check slice memory usage and systemd journal.";
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
