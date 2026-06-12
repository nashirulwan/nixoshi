{ config, lib, pkgs, inputs, ... }:

let
  noctaliaPackage = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  noctaliaWallpaperDir = "${noctaliaPackage}/share/noctalia-shell/Assets/Wallpaper";
  noctaliaMutableSettings = "${config.home.homeDirectory}/nixoshi/home/nashiru/noctalia-settings.mutable.json";
  hyperhdrMusicEffect = "Music: stereo for LED strip (MULTI COLOR FAST)";

  hyperhdrAudioRoute = pkgs.writeShellScript "hyperhdr-audio-route" ''
    set -u

    hyperhdr_url="http://127.0.0.1:8090"
    playback_node="''${HYPERHDR_PLAYBACK_NODE:-$(${pkgs.pulseaudio}/bin/pactl get-default-sink 2>/dev/null || true)}"
    capture_node="''${HYPERHDR_CAPTURE_NODE:-alsa_capture.hyperhdr}"

    if [ -z "$playback_node" ]; then
      exit 0
    fi

    for _ in $(seq 1 60); do
      if ${pkgs.curl}/bin/curl -fsS "$hyperhdr_url/json-rpc" \
        -H 'Content-Type: application/json' \
        -d '{"command":"serverinfo"}' >/dev/null 2>&1; then
        break
      fi
      sleep 0.5
    done

    ${pkgs.pulseaudio}/bin/pactl set-default-source "$playback_node.monitor" >/dev/null 2>&1 || true

    for _ in $(seq 1 80); do
      if ${pkgs.pipewire}/bin/pw-link -io | ${pkgs.gnugrep}/bin/grep -Fxq "$capture_node:input_FL" &&
         ${pkgs.pipewire}/bin/pw-link -io | ${pkgs.gnugrep}/bin/grep -Fxq "$playback_node:monitor_FL"; then
        break
      fi
      sleep 0.25
    done

    ${pkgs.pipewire}/bin/pw-link -d easyeffects_source:capture_FL "$capture_node:input_FL" >/dev/null 2>&1 || true
    ${pkgs.pipewire}/bin/pw-link -d easyeffects_source:capture_FR "$capture_node:input_FR" >/dev/null 2>&1 || true
    ${pkgs.pipewire}/bin/pw-link "$playback_node:monitor_FL" "$capture_node:input_FL" >/dev/null 2>&1 || true
    ${pkgs.pipewire}/bin/pw-link "$playback_node:monitor_FR" "$capture_node:input_FR" >/dev/null 2>&1 || true
  '';

  hyperhdrSession = pkgs.writeShellScriptBin "hyperhdr-session" ''
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ pkgs.libglvnd ]}:''${LD_LIBRARY_PATH:-}:/run/opengl-driver/lib"
    export LIBGL_DRIVERS_PATH="/run/opengl-driver/lib/dri''${LIBGL_DRIVERS_PATH:+:$LIBGL_DRIVERS_PATH}"
    exec ${pkgs.hyperhdr}/bin/hyperhdr "$@"
  '';

  hyperhdrMusic = pkgs.writeShellScriptBin "hyperhdr-music" ''
    set -e

    ${pkgs.curl}/bin/curl -fsS http://127.0.0.1:8090/json-rpc \
      -H 'Content-Type: application/json' \
      -d "$(${pkgs.jq}/bin/jq -nc --arg effect "${hyperhdrMusicEffect}" \
        '{command:"effect", effect:{name:$effect}, priority:100}')"

    ${hyperhdrAudioRoute}
  '';

  hyperhdrMonitor = pkgs.writeShellScriptBin "hyperhdr-monitor" ''
    set -e

    ${pkgs.curl}/bin/curl -fsS http://127.0.0.1:8090/json-rpc \
      -H 'Content-Type: application/json' \
      -d '{"command":"clear","priority":100}'

    ${pkgs.curl}/bin/curl -fsS http://127.0.0.1:8090/json-rpc \
      -H 'Content-Type: application/json' \
      -d '{"command":"clear","priority":1}' >/dev/null 2>&1 || true
  '';



  hyperhdrStartupSync = pkgs.writeShellScript "hyperhdr-startup-sync" ''
    set -eu
    # systemd user services have a minimal PATH; ensure coreutils resolve.
    export PATH=${pkgs.coreutils}/bin:$PATH

    manager_env=""
    wayland_display=""
    # Wait for a valid WAYLAND_DISPLAY socket before acquiring the stream.
    i=0
    while [ "$i" -lt 60 ]; do
      manager_env="$(${pkgs.systemd}/bin/systemctl --user show-environment 2>/dev/null || true)"
      wayland_display="$(printf '%s\n' "$manager_env" | ${pkgs.gnused}/bin/sed -n 's/^WAYLAND_DISPLAY=//p' | head -n1)"

      if [ -n "$wayland_display" ] && [ -S "/run/user/$UID/$wayland_display" ]; then
        break
      fi

      sleep 0.5
      i=$((i + 1))
    done

    # Let PipeWire/portal settle before asking HyperHDR to acquire a monitor stream.
    sleep 6

    ${pkgs.systemd}/bin/systemctl --user restart hyperhdr.service

    i=0
    while [ "$i" -lt 40 ]; do
      if ${pkgs.curl}/bin/curl -fsS http://127.0.0.1:8090/json-rpc \
        -H 'Content-Type: application/json' \
        -d '{"command":"serverinfo"}' >/dev/null 2>&1; then
        break
      fi
      sleep 0.5
      i=$((i + 1))
    done

    ${hyperhdrMonitor}/bin/hyperhdr-monitor >/dev/null 2>&1 || true
  '';

  # Turning the external monitor off drops HDMI-A-1 (HPD), which kills the
  # screencast stream HyperHDR captures; it does not reconnect on its own.
  # Poll for the output coming back and re-sync once when it does.
  hyperhdrHdmiWatch = pkgs.writeShellScript "hyperhdr-hdmi-watch" ''
    set -u
    export PATH=${pkgs.coreutils}/bin:$PATH
    state="$HOME/.cache/hyperhdr-hdmi-present"
    present=no
    ${pkgs.wlr-randr}/bin/wlr-randr 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q '^HDMI-A-1' && present=yes
    prev="$(cat "$state" 2>/dev/null || echo unknown)"
    printf '%s' "$present" > "$state"
    if [ "$present" = yes ] && [ "$prev" = no ]; then
      ${pkgs.systemd}/bin/systemctl --user start hyperhdr-startup-sync.service
    fi
  '';

in

{
  # Home Manager version
  home.stateVersion = "24.11";
  
  # User information
  home.username = "nashiru";
  home.homeDirectory = "/home/nashiru";
  
  home.packages = with pkgs; [
    hyperhdrSession
    hyperhdrMusic
    hyperhdrMonitor
    kitty
    jq
    bibata-cursors
    obsidian
  ];

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };

  xdg.configFile = {
    "ghostty/config".text = ''
      theme = noctalia
    '';
    "noctalia/settings.json".source = lib.mkForce (config.lib.file.mkOutOfStoreSymlink noctaliaMutableSettings);
    "wezterm/wezterm.lua".text = ''
      local wezterm = require("wezterm")

      return {
        color_scheme = "Noctalia",
        font = wezterm.font("JetBrainsMono Nerd Font"),
        font_size = 11.0,
        hide_tab_bar_if_only_one_tab = true,
        window_background_opacity = 0.94,
      }
    '';
  };
  
  # Import user modules
  imports = [
    inputs.noctalia.homeModules.default
    inputs.mango.hmModules.mango
    ./programs/git.nix
    ./programs/yazi.nix
    ./programs/kitty.nix
    ./programs/btop.nix
    ./programs/fastfetch.nix
    ./shell/fish.nix
    ./theme.nix
    ./mango.nix
  ];

  programs.noctalia-shell = {
    enable = true;
    settings = {
      bar = {
        barType = "simple";
        position = "top";
        density = "default";
        showCapsule = true;
        backgroundOpacity = 0.93;
        marginVertical = 4;
        marginHorizontal = 4;
        frameThickness = 8;
        frameRadius = 12;
        outerCorners = true;
        widgets = {
          left = [
            { id = "Launcher"; }
            { id = "Clock"; }
            { id = "SystemMonitor"; }
            { id = "ActiveWindow"; }
            { id = "MediaMini"; }
          ];
          center = [
            {
              id = "Workspace";
              hideUnoccupied = false;
            }
          ];
          right = [
            { id = "Tray"; }
            { id = "NotificationHistory"; }
            { id = "Battery"; }
            { id = "Volume"; }
            { id = "Brightness"; }
            {
              id = "ControlCenter";
            }
          ];
        };
      };
      colorSchemes = {
        predefinedScheme = "Noctalia (default)";
        darkMode = true;
        useWallpaperColors = true;
        syncGsettings = true;
      };
      templates = {
        enableUserTheming = true;
        activeTemplates = map (id: {
          inherit id;
          enabled = true;
        }) [
          "gtk"
          "qt"
          "kcolorscheme"
          "foot"
          "ghostty"
          "kitty"
          "alacritty"
          "wezterm"
          "starship"
          "fuzzel"
          "vicinae"
          "walker"
          "pywalfox"
          "discord"
          "code"
          "zed"
          "helix"
          "telegram"
          "cava"
          "yazi"
          "emacs"
          "niri"
          "mango"
          "btop"
          "zathura"
          "steam"
        ];
      };
      controlCenter = {
        position = "close_to_bar_button";
        cards = [
          {
            enabled = true;
            id = "profile-card";
          }
          {
            enabled = true;
            id = "shortcuts-card";
          }
          {
            enabled = true;
            id = "audio-card";
          }
          {
            enabled = true;
            id = "weather-card";
          }
          {
            enabled = true;
            id = "media-sysmon-card";
          }
        ];
      };
      dock = {
        enabled = true;
        position = "bottom";
        displayMode = "auto_hide";
        dockType = "floating";
        backgroundOpacity = 1;
        size = 1;
        showLauncherIcon = true;
        launcherPosition = "end";
      };
      desktopWidgets = {
        enabled = true;
        overviewEnabled = true;
        gridSnap = true;
        gridSnapScale = true;
        monitorWidgets = [
          {
            name = "eDP-1";
            widgets = [
              {
                id = "Clock";
                x = 48;
                y = 96;
                scale = 1.0;
                showBackground = true;
                roundedCorners = true;
                clockStyle = "digital";
                format = "HH:mm\\nd MMMM yyyy";
              }
              {
                id = "Weather";
                x = 48;
                y = 288;
                scale = 1.0;
                showBackground = true;
                roundedCorners = true;
              }
              {
                id = "MediaPlayer";
                x = 48;
                y = 456;
                scale = 1.0;
                showBackground = true;
                roundedCorners = true;
                showAlbumArt = true;
                showVisualizer = true;
                showButtons = true;
              }
              {
                id = "SystemStat";
                x = 1480;
                y = 96;
                scale = 1.0;
                showBackground = true;
                roundedCorners = true;
                statType = "CPU";
                layout = "bottom";
              }
              {
                id = "AudioVisualizer";
                x = 1320;
                y = 800;
                scale = 1.0;
                showBackground = true;
                roundedCorners = true;
                width = 320;
                height = 72;
                visualizerType = "linear";
                hideWhenIdle = false;
              }
            ];
          }
          {
            name = "HDMI-A-1";
            widgets = [
              {
                id = "Clock";
                x = 64;
                y = 96;
                scale = 1.0;
                showBackground = true;
                roundedCorners = true;
                clockStyle = "digital";
                format = "HH:mm\\nd MMMM yyyy";
              }
              {
                id = "Weather";
                x = 64;
                y = 288;
                scale = 1.0;
                showBackground = true;
                roundedCorners = true;
              }
              {
                id = "MediaPlayer";
                x = 64;
                y = 456;
                scale = 1.0;
                showBackground = true;
                roundedCorners = true;
                showAlbumArt = true;
                showVisualizer = true;
                showButtons = true;
              }
              {
                id = "SystemStat";
                x = 1480;
                y = 96;
                scale = 1.0;
                showBackground = true;
                roundedCorners = true;
                statType = "CPU";
                layout = "bottom";
              }
              {
                id = "AudioVisualizer";
                x = 1320;
                y = 880;
                scale = 1.0;
                showBackground = true;
                roundedCorners = true;
                width = 320;
                height = 72;
                visualizerType = "linear";
                hideWhenIdle = false;
              }
            ];
          }
        ];
      };
      general = {
        radiusRatio = 1;
        enableShadows = true;
        enableBlurBehind = true;
        showScreenCorners = false;
      };
      location = {
        monthBeforeDay = false;
        name = "Jakarta, Indonesia";
        weatherEnabled = true;
        weatherShowEffects = true;
        autoLocate = false;
      };
      notifications = {
        enabled = true;
        location = "top_right";
        enableBatteryToast = true;
        enableKeyboardLayoutToast = true;
      };
      osd = {
        enabled = true;
        location = "top_right";
      };
      wallpaper = {
        enabled = true;
        directory = noctaliaWallpaperDir;
        fillMode = "crop";
        setWallpaperOnAllMonitors = true;
        transitionDuration = 1500;
      };
      appLauncher = {
        enableClipboardHistory = true;
        showCategories = true;
        iconMode = "tabler";
        terminalCommand = "kitty -e";
      };
    };
  };

  home.activation.ensureNoctaliaNiriTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    theme_file="${config.home.homeDirectory}/.config/niri/noctalia.kdl"
    if [ ! -e "$theme_file" ]; then
      mkdir -p "$(dirname "$theme_file")"
      cat > "$theme_file" <<'KDL'
// Generated by Noctalia after the shell starts.
KDL
    fi
  '';

  home.activation.linkMutableNoctaliaSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    settings_dir="${config.home.homeDirectory}/.config/noctalia"
    settings_file="$settings_dir/settings.json"

    mkdir -p "$settings_dir"
    chmod u+w "${noctaliaMutableSettings}" 2>/dev/null || true
    rm -f "$settings_file"
    ln -s "${noctaliaMutableSettings}" "$settings_file"
  '';

  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;

  systemd.user.services.hyperhdr = {
    Unit = {
      Description = "HyperHDR ambient lighting";
      After = [ "graphical-session.target" "pipewire.service" "pipewire-pulse.service" "wireplumber.service" ];
      Wants = [ "pipewire.service" "pipewire-pulse.service" "wireplumber.service" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.hyperhdr}/share/hyperhdr/bin/hyperhdr";
      ExecStartPost = "${hyperhdrAudioRoute}";
      Restart = "on-failure";
      RestartSec = 5;
      # No GL/EGL libs on purpose: with EGL, HyperHDR's DMA-BUF path fails
      # modifier negotiation against xdg-desktop-portal-wlr ("no more input
      # formats", stream dies). Without EGL it falls back to the stable MemFD
      # software path, which is the only one that works on mango + wlr portal.
      Environment = [
        "HYPERHDR_PLAYBACK_NODE=easyeffects_sink"
      ];
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.hyperhdr-startup-sync = {
    Unit = {
      Description = "Delay HyperHDR monitor sync until Wayland session is ready";
      After = [ "graphical-session.target" "pipewire.service" "pipewire-pulse.service" "wireplumber.service" ];
      Wants = [ "pipewire.service" "pipewire-pulse.service" "wireplumber.service" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = hyperhdrStartupSync;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.hyperhdr-audio-route = {
    Unit = {
      Description = "Route playback audio into HyperHDR music effects";
      After = [ "graphical-session.target" "pipewire.service" "pipewire-pulse.service" "wireplumber.service" ];
      Wants = [ "pipewire.service" "pipewire-pulse.service" "wireplumber.service" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${hyperhdrAudioRoute}";
    };
  };

  systemd.user.timers.hyperhdr-audio-route = {
    Unit.Description = "Keep HyperHDR audio routing alive";

    Timer = {
      OnStartupSec = "20s";
      OnUnitActiveSec = "30s";
      Unit = "hyperhdr-audio-route.service";
    };

    Install.WantedBy = [ "timers.target" ];
  };

  # Re-sync HyperHDR automatically when the external monitor comes back on.
  systemd.user.services.hyperhdr-hdmi-watch = {
    Unit.Description = "Re-sync HyperHDR when the captured monitor returns";
    Service = {
      Type = "oneshot";
      ExecStart = hyperhdrHdmiWatch;
    };
  };

  systemd.user.timers.hyperhdr-hdmi-watch = {
    Unit.Description = "Poll for the captured monitor returning";

    Timer = {
      OnStartupSec = "30s";
      OnUnitActiveSec = "15s";
      Unit = "hyperhdr-hdmi-watch.service";
    };

    Install.WantedBy = [ "timers.target" ];
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
