{ config, lib, pkgs, inputs, nixoshiSettingsFile ? null, ... }:

let
  noctaliaPackage = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  codexDesktopPackage = inputs.codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.default;
  noctaliaWallpaperDir = "${noctaliaPackage}/share/noctalia-shell/Assets/Wallpaper";
  renderedNoctaliaSettings = pkgs.replaceVars ./noctalia-settings.mutable.json {
    homeDirectory = config.home.homeDirectory;
    wallpaperDirectory = noctaliaWallpaperDir;
  };
  defaultNoctaliaSettingsFile = "${config.xdg.stateHome}/nixoshi/noctalia-settings.json";
  noctaliaMutableSettings =
    if nixoshiSettingsFile == null
    then defaultNoctaliaSettingsFile
    else nixoshiSettingsFile;
  hyperhdrMusicEffect = "Music: stereo for LED strip (MULTI COLOR FAST)";

  hyperhdrAudioRoute = pkgs.writeShellScript "hyperhdr-audio-route" ''
    set -u
    export PATH=${pkgs.coreutils}/bin:$PATH

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

    # Drop the wlroots portal's restoration state before HyperHDR asks for a
    # new source. Otherwise it may keep trying a disabled output stream.
    ${pkgs.systemd}/bin/systemctl --user restart xdg-desktop-portal-wlr.service 2>/dev/null \
      || ${pkgs.systemd}/bin/systemctl --user start xdg-desktop-portal-wlr.service 2>/dev/null \
      || true
    sleep 1
    ${pkgs.systemd}/bin/systemctl --user restart hyperhdr.service

    server_ready=no
    i=0
    while [ "$i" -lt 40 ]; do
      if ${pkgs.curl}/bin/curl -fsS http://127.0.0.1:8090/json-rpc \
        -H 'Content-Type: application/json' \
        -d '{"command":"serverinfo"}' >/dev/null 2>&1; then
        server_ready=yes
        break
      fi
      sleep 0.5
      i=$((i + 1))
    done

    if [ "$server_ready" != yes ]; then
      echo "HyperHDR JSON-RPC did not become ready after monitor sync" >&2
      exit 1
    fi

    ${hyperhdrMonitor}/bin/hyperhdr-monitor >/dev/null 2>&1
  '';

  # If a consumer chooses a preferred capture output, re-sync HyperHDR when
  # that output becomes enabled again. Without a preference this is a no-op.
  hyperhdrOutputWatch = pkgs.writeShellScript "hyperhdr-output-watch" ''
    set -u
    export PATH=${pkgs.coreutils}/bin:$PATH
    preferred_output="''${HYPERHDR_PREFERRED_OUTPUT:-}"
    if [ -z "$preferred_output" ]; then
      exit 0
    fi

    state="$HOME/.cache/hyperhdr-preferred-output-enabled"
    mkdir -p "$(dirname "$state")"
    present=no
    ${pkgs.wlr-randr}/bin/wlr-randr 2>/dev/null | ${pkgs.gawk}/bin/awk -v target="$preferred_output" '
      $1 == target { in_output = 1; next }
      in_output && $0 !~ /^[[:space:]]/ { in_output = 0 }
      in_output && $0 ~ /^[[:space:]]+Enabled: yes/ { found = 1 }
      END { exit(found ? 0 : 1) }
    ' && present=yes
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
  
  home.packages = with pkgs; [
    codexDesktopPackage
    hyperhdrSession
    hyperhdrMusic
    hyperhdrMonitor
    kitty
    jq
    bibata-cursors
    obsidian
    discord
  ];

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };

  xdg.configFile = {
    "noctalia/settings.json".source = lib.mkForce (config.lib.file.mkOutOfStoreSymlink noctaliaMutableSettings);
  };
  
  # Import user modules
  imports = [
    ./programs/git.nix
    ./programs/yazi.nix
    ./programs/kitty.nix
    ./programs/btop.nix
    ./programs/fastfetch.nix
    ./programs/kimi-code.nix
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
        darkMode = false;
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
          "kitty"
          "alacritty"
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
        monitorWidgets = [];
      };
      general = {
        radiusRatio = 1;
        enableShadows = false;
        enableBlurBehind = false;
        showScreenCorners = false;
      };
      location = {
        monthBeforeDay = false;
        weatherEnabled = false;
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
    settings_target="${noctaliaMutableSettings}"

    mkdir -p "$settings_dir"
    mkdir -p "$(dirname "$settings_target")"
    if [ ! -e "$settings_target" ]; then
      ${pkgs.coreutils}/bin/install -m 600 ${renderedNoctaliaSettings} "$settings_target"
    fi
    chmod u+w "$settings_target" 2>/dev/null || true
    rm -f "$settings_file"
    ln -s "$settings_target" "$settings_file"
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

  # Re-sync HyperHDR when an optional preferred output becomes enabled again.
  systemd.user.services.hyperhdr-output-watch = {
    Unit.Description = "Re-sync HyperHDR when the preferred output returns";
    Service = {
      Type = "oneshot";
      ExecStart = hyperhdrOutputWatch;
    };
  };

  systemd.user.timers.hyperhdr-output-watch = {
    Unit.Description = "Poll for the preferred capture output returning";

    Timer = {
      OnStartupSec = "30s";
      OnUnitActiveSec = "15s";
      Unit = "hyperhdr-output-watch.service";
    };

    Install.WantedBy = [ "timers.target" ];
  };

  # Obsidian — auto-start for LiveSync background sync
  systemd.user.services.obsidian = {
    Unit = {
      Description = "Obsidian (background sync for LiveSync)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "idle";
      ExecStart = "${pkgs.obsidian}/bin/obsidian --ozone-platform=wayland";
      Restart = "on-failure";
      RestartSec = 15;
      Environment = [ "GDK_BACKEND=wayland" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
