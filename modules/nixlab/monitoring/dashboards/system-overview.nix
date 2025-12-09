# Dashboard generator function that accepts memory limits
{ memoryLimits }:

let
  # Extract limits for readability
  netMax = memoryLimits.network.max;
  monMax = memoryLimits.monitoring.max;
  mediaSysMax = memoryLimits.mediaSystem.max;
  mediaUserMax = memoryLimits.mediaUser.max;
in

builtins.toJSON {
  id = null;
  uid = "ab45f308-4dd8-4010-908c-77a58080ca71";
  title = "Nixlab System Overview";
  tags = [
    "system"
    "nixlab"
  ];
  timezone = "browser";
  refresh = "30s";
  time = {
    from = "now-1h";
    to = "now";
  };
  panels = [
    {
      id = 1;
      title = "CPU Usage";
      type = "timeseries";
      targets = [
        {
          expr = "100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\",instance=\"nixlab\"}[5m])) * 100)";
          legendFormat = "CPU %";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "80";
          legendFormat = "Alert Threshold (80%)";
          datasource = "VictoriaMetrics";
        }
      ];
      gridPos = {
        h = 4;
        w = 6;
        x = 0;
        y = 0;
      };
      fieldConfig = {
        defaults = {
          unit = "percent";
          min = 0;
          max = 100;
          custom = {
            fillOpacity = 10;
            showPoints = "never";
            lineWidth = 2;
          };
        };
        overrides = [
          {
            matcher = {
              id = "byName";
              options = "Alert Threshold (80%)";
            };
            properties = [
              {
                id = "custom.lineStyle";
                value = {
                  fill = "dash";
                };
              }
              {
                id = "custom.lineWidth";
                value = 2;
              }
              {
                id = "color";
                value = {
                  mode = "fixed";
                  fixedColor = "red";
                };
              }
            ];
          }
        ];
      };
      options = {
        legend = {
          showLegend = true;
          displayMode = "list";
          placement = "bottom";
        };
      };
    }
    {
      id = 2;
      title = "Memory Usage";
      type = "timeseries";
      targets = [
        {
          expr = "100 - (node_memory_MemAvailable_bytes{instance=\"nixlab\"} / node_memory_MemTotal_bytes{instance=\"nixlab\"} * 100)";
          legendFormat = "Memory %";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "80";
          legendFormat = "Warning Threshold (80%)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "90";
          legendFormat = "Critical Threshold (90%)";
          datasource = "VictoriaMetrics";
        }
      ];
      gridPos = {
        h = 4;
        w = 6;
        x = 6;
        y = 0;
      };
      fieldConfig = {
        defaults = {
          unit = "percent";
          min = 0;
          max = 100;
          custom = {
            fillOpacity = 10;
            showPoints = "never";
            lineWidth = 2;
          };
        };
        overrides = [
          {
            matcher = {
              id = "byName";
              options = "Warning Threshold (80%)";
            };
            properties = [
              {
                id = "custom.lineStyle";
                value = {
                  fill = "dash";
                };
              }
              {
                id = "custom.lineWidth";
                value = 2;
              }
              {
                id = "color";
                value = {
                  mode = "fixed";
                  fixedColor = "yellow";
                };
              }
            ];
          }
          {
            matcher = {
              id = "byName";
              options = "Critical Threshold (90%)";
            };
            properties = [
              {
                id = "custom.lineStyle";
                value = {
                  fill = "dash";
                };
              }
              {
                id = "custom.lineWidth";
                value = 2;
              }
              {
                id = "color";
                value = {
                  mode = "fixed";
                  fixedColor = "red";
                };
              }
            ];
          }
        ];
      };
      options = {
        legend = {
          showLegend = true;
          displayMode = "list";
          placement = "bottom";
        };
      };
    }
    {
      id = 3;
      title = "Disk Usage";
      type = "timeseries";
      targets = [
        {
          expr = "100 - (node_filesystem_avail_bytes{instance=\"nixlab\",mountpoint=\"/\"} / node_filesystem_size_bytes{instance=\"nixlab\",mountpoint=\"/\"} * 100)";
          legendFormat = "Disk %";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "90";
          legendFormat = "Critical Threshold (90%)";
          datasource = "VictoriaMetrics";
        }
      ];
      gridPos = {
        h = 4;
        w = 6;
        x = 12;
        y = 0;
      };
      fieldConfig = {
        defaults = {
          unit = "percent";
          min = 0;
          max = 100;
          custom = {
            fillOpacity = 10;
            showPoints = "never";
            lineWidth = 2;
          };
        };
        overrides = [
          {
            matcher = {
              id = "byName";
              options = "Critical Threshold (90%)";
            };
            properties = [
              {
                id = "custom.lineStyle";
                value = {
                  fill = "dash";
                };
              }
              {
                id = "custom.lineWidth";
                value = 2;
              }
              {
                id = "color";
                value = {
                  mode = "fixed";
                  fixedColor = "red";
                };
              }
            ];
          }
        ];
      };
      options = {
        legend = {
          showLegend = true;
          displayMode = "list";
          placement = "bottom";
        };
      };
    }
    {
      id = 4;
      title = "Load Average";
      type = "timeseries";
      targets = [
        {
          expr = "node_load15{instance=\"nixlab\"}";
          legendFormat = "Load 15m";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "count(node_cpu_seconds_total{instance=\"nixlab\",mode=\"idle\"}) * 2";
          legendFormat = "Alert Threshold (2x CPUs)";
          datasource = "VictoriaMetrics";
        }
      ];
      gridPos = {
        h = 4;
        w = 6;
        x = 18;
        y = 0;
      };
      fieldConfig = {
        defaults = {
          unit = "short";
          decimals = 2;
          min = 0;
          custom = {
            fillOpacity = 10;
            showPoints = "never";
            lineWidth = 2;
          };
        };
        overrides = [
          {
            matcher = {
              id = "byName";
              options = "Alert Threshold (2x CPUs)";
            };
            properties = [
              {
                id = "custom.lineStyle";
                value = {
                  fill = "dash";
                };
              }
              {
                id = "custom.lineWidth";
                value = 2;
              }
              {
                id = "color";
                value = {
                  mode = "fixed";
                  fixedColor = "red";
                };
              }
            ];
          }
        ];
      };
      options = {
        legend = {
          showLegend = true;
          displayMode = "list";
          placement = "bottom";
        };
      };
    }
    {
      id = 5;
      title = "Service Health";
      type = "status-history";
      targets = [
        {
          expr = "caddy_reverse_proxy_upstreams_healthy";
          legendFormat = "{{service}}";
          datasource = "VictoriaMetrics";
        }
      ];
      gridPos = {
        h = 8;
        w = 24;
        x = 0;
        y = 4;
      };
      fieldConfig = {
        defaults = {
          unit = "short";
          thresholds = {
            mode = "absolute";
            steps = [
              {
                color = "red";
                value = 0;
              }
              {
                color = "green";
                value = 1;
              }
            ];
          };
          mappings = [
            {
              options = {
                "0" = {
                  text = "DOWN";
                };
              };
              type = "value";
            }
            {
              options = {
                "1" = {
                  text = "UP";
                };
              };
              type = "value";
            }
          ];
        };
      };
      options = {
        showValue = "auto";
        rowHeight = 0.9;
        colWidth = 0.9;
        legendDisplayMode = "list";
        legendPlacement = "bottom";
      };
    }
    {
      id = 6;
      title = "HTTP Requests/sec";
      type = "timeseries";
      targets = [
        {
          expr = "sum(rate(caddy_http_requests_total{instance=\"nixlab\"}[5m])) by (host)";
          legendFormat = "{{host}}";
          datasource = "VictoriaMetrics";
        }
      ];
      gridPos = {
        h = 8;
        w = 12;
        x = 0;
        y = 12;
      };
      fieldConfig = {
        defaults = {
          unit = "reqps";
        };
      };
    }
    {
      id = 7;
      title = "HTTP Response Times";
      type = "timeseries";
      targets = [
        {
          expr = "histogram_quantile(0.95, sum(rate(caddy_http_request_duration_seconds_bucket{instance=\"nixlab\"}[5m])) by (le, host))";
          legendFormat = "95th percentile - {{host}}";
          datasource = "VictoriaMetrics";
        }
      ];
      gridPos = {
        h = 8;
        w = 12;
        x = 12;
        y = 12;
      };
      fieldConfig = {
        defaults = {
          unit = "s";
        };
      };
    }
    {
      id = 8;
      title = "System Errors & Critical Issues";
      type = "logs";
      targets = [
        {
          expr = "{job=\"systemd-journal\",instance=\"nixlab\",priority=~\"0|1|2|3\"}";
          datasource = "VictoriaLogs";
        }
      ];
      gridPos = {
        h = 10;
        w = 24;
        x = 0;
        y = 20;
      };
      options = {
        showTime = true;
        showLabels = true;
        showCommonLabels = false;
        wrapLogMessage = true;
        sortOrder = "Descending";
        dedupStrategy = "none";
      };
    }
    {
      id = 9;
      title = "Systemd Slice Memory Usage";
      type = "timeseries";
      targets = [
        {
          expr = "sum(cgroup_memory_current_bytes{instance=\"nixlab\",cgroup=~\"network\\\\.slice/.*\"}) / 1024 / 1024";
          legendFormat = "network.slice usage (MB)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "sum(cgroup_memory_current_bytes{instance=\"nixlab\",cgroup=~\"monitoring\\\\.slice/.*\"}) / 1024 / 1024";
          legendFormat = "monitoring.slice usage (MB)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "sum(cgroup_memory_current_bytes{instance=\"nixlab\",cgroup=~\"media\\\\.slice/.*\"}) / 1024 / 1024";
          legendFormat = "media.slice (system) usage (MB)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "sum(cgroup_memory_current_bytes{instance=\"nixlab\",cgroup=~\"user\\\\.slice/user-1000\\\\.slice/user@1000\\\\.service/media\\\\.slice/.*\"}) / 1024 / 1024";
          legendFormat = "media.slice (user) usage (MB)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "${toString netMax}";
          legendFormat = "network.slice limit (MB)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "${toString monMax}";
          legendFormat = "monitoring.slice limit (MB)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "${toString mediaSysMax}";
          legendFormat = "media.slice (system) limit (MB)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "${toString mediaUserMax}";
          legendFormat = "media.slice (user) limit (MB)";
          datasource = "VictoriaMetrics";
        }
      ];
      gridPos = {
        h = 8;
        w = 12;
        x = 0;
        y = 30;
      };
      fieldConfig = {
        defaults = {
          unit = "decmbytes";
          min = 0;
          custom = {
            fillOpacity = 10;
            showPoints = "never";
            lineWidth = 2;
            stacking = {
              mode = "none";
            };
          };
        };
        overrides = [
          {
            matcher = {
              id = "byRegexp";
              options = ".*limit.*";
            };
            properties = [
              {
                id = "custom.lineStyle";
                value = {
                  fill = "dash";
                };
              }
              {
                id = "custom.lineWidth";
                value = 1;
              }
              {
                id = "color";
                value = {
                  mode = "fixed";
                  fixedColor = "red";
                };
              }
              {
                id = "custom.fillOpacity";
                value = 0;
              }
            ];
          }
        ];
      };
      options = {
        legend = {
          showLegend = true;
          displayMode = "table";
          placement = "bottom";
          calcs = [
            "lastNotNull"
            "max"
          ];
        };
        tooltip = {
          mode = "multi";
        };
      };
    }
    {
      id = 10;
      title = "Slice Memory Utilization %";
      type = "timeseries";
      targets = [
        {
          expr = "sum(cgroup_memory_current_bytes{instance=\"nixlab\",cgroup=~\"network\\\\.slice/.*\"}) / (${toString netMax} * 1024 * 1024) * 100";
          legendFormat = "network.slice";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "sum(cgroup_memory_current_bytes{instance=\"nixlab\",cgroup=~\"monitoring\\\\.slice/.*\"}) / (${toString monMax} * 1024 * 1024) * 100";
          legendFormat = "monitoring.slice";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "sum(cgroup_memory_current_bytes{instance=\"nixlab\",cgroup=~\"media\\\\.slice/.*\"}) / (${toString mediaSysMax} * 1024 * 1024) * 100";
          legendFormat = "media.slice (system)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "sum(cgroup_memory_current_bytes{instance=\"nixlab\",cgroup=~\"user\\\\.slice/user-1000\\\\.slice/user@1000\\\\.service/media\\\\.slice/.*\"}) / (${toString mediaUserMax} * 1024 * 1024) * 100";
          legendFormat = "media.slice (user)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "80";
          legendFormat = "Warning (80%)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "100";
          legendFormat = "Limit (100%)";
          datasource = "VictoriaMetrics";
        }
      ];
      gridPos = {
        h = 8;
        w = 12;
        x = 12;
        y = 30;
      };
      fieldConfig = {
        defaults = {
          unit = "percent";
          min = 0;
          max = 100;
          custom = {
            fillOpacity = 10;
            showPoints = "never";
            lineWidth = 2;
          };
        };
        overrides = [
          {
            matcher = {
              id = "byName";
              options = "Warning (80%)";
            };
            properties = [
              {
                id = "custom.lineStyle";
                value = {
                  fill = "dash";
                };
              }
              {
                id = "custom.lineWidth";
                value = 1;
              }
              {
                id = "color";
                value = {
                  mode = "fixed";
                  fixedColor = "yellow";
                };
              }
            ];
          }
          {
            matcher = {
              id = "byName";
              options = "Limit (100%)";
            };
            properties = [
              {
                id = "custom.lineStyle";
                value = {
                  fill = "dash";
                };
              }
              {
                id = "custom.lineWidth";
                value = 1;
              }
              {
                id = "color";
                value = {
                  mode = "fixed";
                  fixedColor = "red";
                };
              }
            ];
          }
        ];
      };
      options = {
        legend = {
          showLegend = true;
          displayMode = "list";
          placement = "bottom";
        };
      };
    }
    {
      id = 11;
      title = "Network Slice Memory Detail";
      type = "timeseries";
      targets = [
        {
          expr = "cgroup_memory_anon_bytes{instance=\"nixlab\",cgroup=~\"network\\\\.slice/.*\\\\.service\"} / 1024 / 1024";
          legendFormat = "{{cgroup}} (process)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "cgroup_memory_file_bytes{instance=\"nixlab\",cgroup=~\"network\\\\.slice/.*\\\\.service\"} / 1024 / 1024";
          legendFormat = "{{cgroup}} (cache)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "cgroup_memory_kernel_bytes{instance=\"nixlab\",cgroup=~\"network\\\\.slice/.*\\\\.service\"} / 1024 / 1024";
          legendFormat = "{{cgroup}} (kernel)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "${toString netMax}";
          legendFormat = "Slice Limit (${toString netMax}MB)";
          datasource = "VictoriaMetrics";
        }
      ];
      gridPos = {
        h = 8;
        w = 12;
        x = 0;
        y = 38;
      };
      fieldConfig = {
        defaults = {
          unit = "decmbytes";
          min = 0;
          custom = {
            fillOpacity = 70;
            showPoints = "never";
            lineWidth = 1;
            stacking = {
              mode = "normal";
              group = "A";
            };
          };
        };
        overrides = [
          {
            matcher = {
              id = "byRegexp";
              options = ".*\\(process\\)";
            };
            properties = [
              {
                id = "color";
                value = {
                  mode = "palette-classic";
                };
              }
              {
                id = "custom.fillOpacity";
                value = 100;
              }
              {
                id = "custom.lineWidth";
                value = 2;
              }
            ];
          }
          {
            matcher = {
              id = "byRegexp";
              options = ".*\\(cache\\)";
            };
            properties = [
              {
                id = "custom.fillOpacity";
                value = 50;
              }
            ];
          }
          {
            matcher = {
              id = "byRegexp";
              options = ".*\\(kernel\\)";
            };
            properties = [
              {
                id = "custom.fillOpacity";
                value = 30;
              }
            ];
          }
          {
            matcher = {
              id = "byRegexp";
              options = "Slice Limit.*";
            };
            properties = [
              {
                id = "custom.lineStyle";
                value = {
                  fill = "dash";
                };
              }
              {
                id = "custom.lineWidth";
                value = 2;
              }
              {
                id = "color";
                value = {
                  mode = "fixed";
                  fixedColor = "red";
                };
              }
              {
                id = "custom.fillOpacity";
                value = 0;
              }
              {
                id = "custom.stacking";
                value = {
                  mode = "none";
                };
              }
            ];
          }
        ];
      };
      options = {
        legend = {
          showLegend = true;
          displayMode = "table";
          placement = "bottom";
          calcs = [
            "lastNotNull"
            "max"
          ];
        };
      };
    }
    {
      id = 12;
      title = "Monitoring Slice Memory Detail";
      type = "timeseries";
      targets = [
        {
          expr = "cgroup_memory_anon_bytes{instance=\"nixlab\",cgroup=~\"monitoring\\\\.slice/.*\\\\.service\"} / 1024 / 1024";
          legendFormat = "{{cgroup}} (process)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "cgroup_memory_file_bytes{instance=\"nixlab\",cgroup=~\"monitoring\\\\.slice/.*\\\\.service\"} / 1024 / 1024";
          legendFormat = "{{cgroup}} (cache)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "cgroup_memory_kernel_bytes{instance=\"nixlab\",cgroup=~\"monitoring\\\\.slice/.*\\\\.service\"} / 1024 / 1024";
          legendFormat = "{{cgroup}} (kernel)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "${toString monMax}";
          legendFormat = "Slice Limit (${toString monMax}MB)";
          datasource = "VictoriaMetrics";
        }
      ];
      gridPos = {
        h = 8;
        w = 12;
        x = 12;
        y = 38;
      };
      fieldConfig = {
        defaults = {
          unit = "decmbytes";
          min = 0;
          custom = {
            fillOpacity = 70;
            showPoints = "never";
            lineWidth = 1;
            stacking = {
              mode = "normal";
              group = "A";
            };
          };
        };
        overrides = [
          {
            matcher = {
              id = "byRegexp";
              options = ".*\\(process\\)";
            };
            properties = [
              {
                id = "color";
                value = {
                  mode = "palette-classic";
                };
              }
              {
                id = "custom.fillOpacity";
                value = 100;
              }
              {
                id = "custom.lineWidth";
                value = 2;
              }
            ];
          }
          {
            matcher = {
              id = "byRegexp";
              options = ".*\\(cache\\)";
            };
            properties = [
              {
                id = "custom.fillOpacity";
                value = 50;
              }
            ];
          }
          {
            matcher = {
              id = "byRegexp";
              options = ".*\\(kernel\\)";
            };
            properties = [
              {
                id = "custom.fillOpacity";
                value = 30;
              }
            ];
          }
          {
            matcher = {
              id = "byRegexp";
              options = "Slice Limit.*";
            };
            properties = [
              {
                id = "custom.lineStyle";
                value = {
                  fill = "dash";
                };
              }
              {
                id = "custom.lineWidth";
                value = 2;
              }
              {
                id = "color";
                value = {
                  mode = "fixed";
                  fixedColor = "red";
                };
              }
              {
                id = "custom.fillOpacity";
                value = 0;
              }
              {
                id = "custom.stacking";
                value = {
                  mode = "none";
                };
              }
            ];
          }
        ];
      };
      options = {
        legend = {
          showLegend = true;
          displayMode = "table";
          placement = "bottom";
          calcs = [
            "lastNotNull"
            "max"
          ];
        };
      };
    }
    {
      id = 13;
      title = "Media Slice (System) Memory Detail";
      type = "timeseries";
      targets = [
        {
          expr = "cgroup_memory_anon_bytes{instance=\"nixlab\",cgroup=~\"media\\\\.slice/.*\\\\.service\"} / 1024 / 1024";
          legendFormat = "{{cgroup}} (process)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "cgroup_memory_file_bytes{instance=\"nixlab\",cgroup=~\"media\\\\.slice/.*\\\\.service\"} / 1024 / 1024";
          legendFormat = "{{cgroup}} (cache)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "cgroup_memory_kernel_bytes{instance=\"nixlab\",cgroup=~\"media\\\\.slice/.*\\\\.service\"} / 1024 / 1024";
          legendFormat = "{{cgroup}} (kernel)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "${toString mediaSysMax}";
          legendFormat = "Slice Limit (${toString mediaSysMax}MB)";
          datasource = "VictoriaMetrics";
        }
      ];
      gridPos = {
        h = 8;
        w = 12;
        x = 0;
        y = 46;
      };
      fieldConfig = {
        defaults = {
          unit = "decmbytes";
          min = 0;
          custom = {
            fillOpacity = 70;
            showPoints = "never";
            lineWidth = 1;
            stacking = {
              mode = "normal";
              group = "A";
            };
          };
        };
        overrides = [
          {
            matcher = {
              id = "byRegexp";
              options = ".*\\(process\\)";
            };
            properties = [
              {
                id = "color";
                value = {
                  mode = "palette-classic";
                };
              }
              {
                id = "custom.fillOpacity";
                value = 100;
              }
              {
                id = "custom.lineWidth";
                value = 2;
              }
            ];
          }
          {
            matcher = {
              id = "byRegexp";
              options = ".*\\(cache\\)";
            };
            properties = [
              {
                id = "custom.fillOpacity";
                value = 50;
              }
            ];
          }
          {
            matcher = {
              id = "byRegexp";
              options = ".*\\(kernel\\)";
            };
            properties = [
              {
                id = "custom.fillOpacity";
                value = 30;
              }
            ];
          }
          {
            matcher = {
              id = "byRegexp";
              options = "Slice Limit.*";
            };
            properties = [
              {
                id = "custom.lineStyle";
                value = {
                  fill = "dash";
                };
              }
              {
                id = "custom.lineWidth";
                value = 2;
              }
              {
                id = "color";
                value = {
                  mode = "fixed";
                  fixedColor = "red";
                };
              }
              {
                id = "custom.fillOpacity";
                value = 0;
              }
              {
                id = "custom.stacking";
                value = {
                  mode = "none";
                };
              }
            ];
          }
        ];
      };
      options = {
        legend = {
          showLegend = true;
          displayMode = "table";
          placement = "bottom";
          calcs = [
            "lastNotNull"
            "max"
          ];
        };
      };
    }
    {
      id = 14;
      title = "Media Slice (User) Memory Detail";
      type = "timeseries";
      targets = [
        {
          expr = "cgroup_memory_anon_bytes{instance=\"nixlab\",cgroup=~\"user\\\\.slice/user-1000\\\\.slice/user@1000\\\\.service/media\\\\.slice/.*\\\\.service.*\"} / 1024 / 1024";
          legendFormat = "{{cgroup}} (process)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "cgroup_memory_file_bytes{instance=\"nixlab\",cgroup=~\"user\\\\.slice/user-1000\\\\.slice/user@1000\\\\.service/media\\\\.slice/.*\\\\.service.*\"} / 1024 / 1024";
          legendFormat = "{{cgroup}} (cache)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "cgroup_memory_kernel_bytes{instance=\"nixlab\",cgroup=~\"user\\\\.slice/user-1000\\\\.slice/user@1000\\\\.service/media\\\\.slice/.*\\\\.service.*\"} / 1024 / 1024";
          legendFormat = "{{cgroup}} (kernel)";
          datasource = "VictoriaMetrics";
        }
        {
          expr = "${toString mediaUserMax}";
          legendFormat = "Slice Limit (${toString mediaUserMax}MB)";
          datasource = "VictoriaMetrics";
        }
      ];
      gridPos = {
        h = 8;
        w = 12;
        x = 12;
        y = 46;
      };
      fieldConfig = {
        defaults = {
          unit = "decmbytes";
          min = 0;
          custom = {
            fillOpacity = 70;
            showPoints = "never";
            lineWidth = 1;
            stacking = {
              mode = "normal";
              group = "A";
            };
          };
        };
        overrides = [
          {
            matcher = {
              id = "byRegexp";
              options = ".*\\(process\\)";
            };
            properties = [
              {
                id = "color";
                value = {
                  mode = "palette-classic";
                };
              }
              {
                id = "custom.fillOpacity";
                value = 100;
              }
              {
                id = "custom.lineWidth";
                value = 2;
              }
            ];
          }
          {
            matcher = {
              id = "byRegexp";
              options = ".*\\(cache\\)";
            };
            properties = [
              {
                id = "custom.fillOpacity";
                value = 50;
              }
            ];
          }
          {
            matcher = {
              id = "byRegexp";
              options = ".*\\(kernel\\)";
            };
            properties = [
              {
                id = "custom.fillOpacity";
                value = 30;
              }
            ];
          }
          {
            matcher = {
              id = "byRegexp";
              options = "Slice Limit.*";
            };
            properties = [
              {
                id = "custom.lineStyle";
                value = {
                  fill = "dash";
                };
              }
              {
                id = "custom.lineWidth";
                value = 2;
              }
              {
                id = "color";
                value = {
                  mode = "fixed";
                  fixedColor = "red";
                };
              }
              {
                id = "custom.fillOpacity";
                value = 0;
              }
              {
                id = "custom.stacking";
                value = {
                  mode = "none";
                };
              }
            ];
          }
        ];
      };
      options = {
        legend = {
          showLegend = true;
          displayMode = "table";
          placement = "bottom";
          calcs = [
            "lastNotNull"
            "max"
          ];
        };
      };
    }
    {
      id = 15;
      title = "OOM Kills (Last 24h)";
      type = "stat";
      targets = [
        {
          expr = "sum(increase(cgroup_memory_events_oom_kill_total{instance=\"nixlab\"}[24h]))";
          legendFormat = "OOM Kills";
          datasource = "VictoriaMetrics";
        }
      ];
      gridPos = {
        h = 8;
        w = 24;
        x = 0;
        y = 54;
      };
      fieldConfig = {
        defaults = {
          unit = "short";
          thresholds = {
            mode = "absolute";
            steps = [
              {
                color = "green";
                value = 0;
              }
              {
                color = "yellow";
                value = 1;
              }
              {
                color = "red";
                value = 5;
              }
            ];
          };
        };
      };
      options = {
        textMode = "value_and_name";
        colorMode = "background";
        graphMode = "area";
        justifyMode = "center";
        orientation = "auto";
      };
    }
  ];
}
