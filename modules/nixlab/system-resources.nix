{ config, lib, ... }:

let
  # Memory allocation constants (in MB)
  # Total VM memory: 11.72GB (~11,720MB)
  # Allocation: 256 + 2560 + 5120 + 3584 = 11,520MB (200MB safety buffer)
  memoryLimits = {
    network = {
      high = 192; # Soft limit - Caddy uses ~66MB
      max = 256; # Hard limit (reduced from 640MB - was 10x oversized)
    };
    monitoring = {
      high = 2304; # Soft limit - peak usage ~2GB
      max = 2560; # Hard limit (reduced from 3.5GB - removed 1GB waste)
    };
    mediaSystem = {
      high = 4608; # Soft limit - allows headroom for Plex transcoding
      max = 5120; # Hard limit (increased from 4GB - was too tight at 92% during transcoding)
    };
    mediaUser = {
      high = 3328; # Soft limit - qBittorrent + containers
      max = 3584; # Hard limit (unchanged - appropriate for workload)
    };
  };
in

{
  options.nixlab.memoryLimits = lib.mkOption {
    type = lib.types.attrs;
    internal = true;
    description = "Memory limits for systemd slices (in MB)";
  };

  config = {
    # Export memory limits for use in dashboards and other modules
    nixlab.memoryLimits = memoryLimits;
    # Enable systemd-oomd for proactive memory pressure management
    systemd.oomd = {
      enable = true;
      enableRootSlice = true;
      enableUserSlices = true;
      enableSystemSlice = true;
    };

    # Memory allocation strategy for 11.72GB total (optimized allocation):
    # Based on actual usage analysis - removed waste, added safety where needed:
    # - System services (critical): no limits, OOMScoreAdjust on individual services
    # - network.slice: 256MB (Caddy: ~66MB, was massively over-allocated at 640MB)
    # - monitoring.slice: 2.5GB (Peak ~2GB: Grafana 189MB + Home Assistant 630MB + Alloy 532MB + VictoriaMetrics/Logs 220MB)
    # - media.slice (system): 5GB (Plex 1.6GB baseline, peaks to 3.7GB during transcoding + *arr services ~1.2GB)
    # - media.slice (user): 3.5GB (qBittorrent + podman containers, appropriate for variable workloads)
    # - Remaining ~200MB safety buffer for system services
    #
    # NOTE: OOMScoreAdjust is NOT valid in [Slice] sections! Only in [Service] sections.

    # System-level slices
    systemd.slices = {
      # Network services
      "network" = {
        sliceConfig = {
          ManagedOOMMemoryPressure = "kill";
          MemoryHigh = "${toString memoryLimits.network.high}M";
          MemoryMax = "${toString memoryLimits.network.max}M";
        };
      };

      # Monitoring stack - optimized to 1.5GB usage after removing plugins & reducing retention
      "monitoring" = {
        sliceConfig = {
          ManagedOOMMemoryPressure = "kill";
          MemoryHigh = "${toString memoryLimits.monitoring.high}M";
          MemoryMax = "${toString memoryLimits.monitoring.max}M";
        };
      };

      # Media services - Arr services are memory-hungry
      "media" = {
        sliceConfig = {
          ManagedOOMMemoryPressure = "kill";
          MemoryHigh = "${toString memoryLimits.mediaSystem.high}M";
          MemoryMax = "${toString memoryLimits.mediaSystem.max}M";
        };
      };
    };

    # User-level slices (for podman containers)
    systemd.user.slices = {
      "media" = {
        sliceConfig = {
          ManagedOOMMemoryPressure = "kill";
          MemoryHigh = "${toString memoryLimits.mediaUser.high}M";
          MemoryMax = "${toString memoryLimits.mediaUser.max}M";
        };
      };
    };

    systemd.services = {
      # Critical services - Can't move to custom slices, but protect via OOMScoreAdjust
      sshd.serviceConfig.OOMScoreAdjust = -900;
      systemd-journald.serviceConfig.OOMScoreAdjust = -800;
      tailscaled.serviceConfig.OOMScoreAdjust = -700;

      # Network services -> network.slice (protected)
      caddy.serviceConfig = {
        Slice = "network.slice";
        OOMScoreAdjust = -600;
      };

      # Monitoring services -> monitoring.slice (high priority)
      grafana.serviceConfig = {
        Slice = "monitoring.slice";
        OOMScoreAdjust = -500;
      };
      alloy.serviceConfig = {
        Slice = "monitoring.slice";
        OOMScoreAdjust = -500;
      };
      victoriametrics.serviceConfig = {
        Slice = "monitoring.slice";
        OOMScoreAdjust = -500;
      };
      victorialogs.serviceConfig = {
        Slice = "monitoring.slice";
        OOMScoreAdjust = -500;
      };
      home-assistant.serviceConfig = {
        Slice = "monitoring.slice";
        OOMScoreAdjust = -400; # Slightly lower priority than metrics/logs
      };

      # Media services -> media.slice (low priority, kill first)
      # *arr services are most expendable - can be restarted without data loss
      sonarr.serviceConfig = {
        Slice = "media.slice";
        OOMScoreAdjust = 500; # Most expendable (increased from 300)
      };
      radarr.serviceConfig = {
        Slice = "media.slice";
        OOMScoreAdjust = 500; # Most expendable (increased from 300)
      };
      lidarr.serviceConfig = {
        Slice = "media.slice";
        OOMScoreAdjust = 500; # Most expendable (increased from 300)
      };
      prowlarr.serviceConfig = {
        Slice = "media.slice";
        OOMScoreAdjust = 500; # Most expendable (increased from 300)
      };
      plex.serviceConfig = {
        Slice = "media.slice";
        OOMScoreAdjust = 200; # More important than *arr - active transcoding would be interrupted
      };
    };

    # NOTE: User service slice assignments (podman containers) are configured in
    # home-manager/home.nix using extraConfig.Service.Slice, as systemd.user.services
    # overrides from system configuration don't apply to home-manager managed services.
  };
}
