{ config, lib, pkgs, inputs, ... }:

let
  noctaliaPackage = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  noctaliaWallpaperDir = "${noctaliaPackage}/share/noctalia-shell/Assets/Wallpaper";
  noctaliaMutableSettings = "${config.home.homeDirectory}/nixoshi/home/nashiru/noctalia-settings.mutable.json";
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
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

in

{
  # Home Manager version
  home.stateVersion = "26.05";
  
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
    spicetify-cli

  ];

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };

  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    settings = {
      background_opacity = "0.94";
      confirm_os_window_close = 0;
      cursor_shape = "beam";
      enable_audio_bell = false;
      hide_window_decorations = "titlebar-only";
      remember_window_size = false;
      initial_window_width = 960;
      initial_window_height = 560;
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      window_padding_width = 8;
    };
    extraConfig = ''
      include themes/noctalia.conf
    '';
  };

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "noctalia";
      theme_background = false;
      vim_keys = true;
    };
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
    inputs.spicetify-nix.homeManagerModules.default
    ./programs/git.nix
    ./programs/yazi.nix
    ./shell/fish.nix
    ./theme.nix
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
        useWallpaperColors = false;
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
          "spicetify"
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

  programs.spicetify = {
    enable = true;

    enabledExtensions = with spicePkgs.extensions; [
      adblockify
      beautifulLyrics
      hidePodcasts
      shuffle
      volumePercentage
    ];

    enabledCustomApps = with spicePkgs.apps; [
      marketplace
      lyricsPlus
    ];
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

  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;

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
  
  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
