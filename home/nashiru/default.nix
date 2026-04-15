{ config, lib, pkgs, inputs, ... }:

let
  hyperhdrMusicEffect = "Music: stereo for LED strip (MULTI COLOR FAST)";

  hyperhdrAudioRoute = pkgs.writeShellScript "hyperhdr-audio-route" ''
    set -u

    hyperhdr_url="http://127.0.0.1:8090"
    effect_name="''${HYPERHDR_MUSIC_EFFECT:-${hyperhdrMusicEffect}}"
    playback_node="''${HYPERHDR_PLAYBACK_NODE:-easyeffects_sink}"
    capture_node="''${HYPERHDR_CAPTURE_NODE:-alsa_capture.hyperhdr}"

    for _ in $(seq 1 60); do
      if ${pkgs.curl}/bin/curl -fsS "$hyperhdr_url/json-rpc" \
        -H 'Content-Type: application/json' \
        -d '{"command":"serverinfo"}' >/dev/null 2>&1; then
        break
      fi
      sleep 0.5
    done

    ${pkgs.pulseaudio}/bin/pactl set-default-source "$playback_node.monitor" >/dev/null 2>&1 || true

    ${pkgs.curl}/bin/curl -fsS "$hyperhdr_url/json-rpc" \
      -H 'Content-Type: application/json' \
      -d "$(${pkgs.jq}/bin/jq -nc --arg effect "$effect_name" \
        '{command:"effect", effect:{name:$effect}, priority:100}')" >/dev/null 2>&1 || true

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

  screenHome = pkgs.writeShellScriptBin "screen-home" ''
    set -e
    ${pkgs.hyprland}/bin/hyprctl keyword monitor "HDMI-A-1,1920x1080@200,0x0,1"
    ${pkgs.hyprland}/bin/hyprctl keyword monitor "eDP-1,disable"
  '';

  screenLaptop = pkgs.writeShellScriptBin "screen-laptop" ''
    set -e
    ${pkgs.hyprland}/bin/hyprctl keyword monitor "eDP-1,preferred,0x0,1"
    ${pkgs.hyprland}/bin/hyprctl dispatch focusmonitor eDP-1 >/dev/null 2>&1 || true
  '';

  screenBoth = pkgs.writeShellScriptBin "screen-both" ''
    set -e
    ${pkgs.hyprland}/bin/hyprctl keyword monitor "HDMI-A-1,1920x1080@200,0x0,1"
    ${pkgs.hyprland}/bin/hyprctl keyword monitor "eDP-1,preferred,1920x0,1"
  '';

  screenToggle = pkgs.writeShellScriptBin "screen-toggle" ''
    set -e

    if ${pkgs.hyprland}/bin/hyprctl monitors all | ${pkgs.gnugrep}/bin/grep -A20 '^Monitor eDP-1' | ${pkgs.gnugrep}/bin/grep -q 'disabled: true'; then
      ${screenLaptop}/bin/screen-laptop
    else
      ${screenHome}/bin/screen-home
    fi
  '';
in

{
  # Home Manager version
  home.stateVersion = "26.05";
  
  # User information
  home.username = "nashiru";
  home.homeDirectory = "/home/nashiru";
  
  home.packages = with pkgs; [
    screenHome
    screenLaptop
    screenBoth
    screenToggle

    # Hyprland Ecosystem
    hyprpaper
    hyprlock
    hypridle

    # Dependencies
    wofi
    dunst
    kitty
    wlogout
    gtk-engine-murrine
    jq
    bibata-cursors

  ];

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };
  
  # Import user modules
  imports = [
    inputs.illogical-flake.homeManagerModules.default
    ./programs/git.nix
    ./programs/yazi.nix
    ./shell/fish.nix
    ./theme.nix
  ];

  programs.illogical-impulse.enable = true;

  xdg.configFile."hypr/hyprland/general.conf".source = lib.mkForce ./hypr/general.conf;

  systemd.user.services.hyperhdr = {
    Unit = {
      Description = "HyperHDR ambient lighting";
      After = [ "graphical-session.target" "pipewire.service" "pipewire-pulse.service" "wireplumber.service" ];
      Wants = [ "pipewire.service" "pipewire-pulse.service" "wireplumber.service" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.hyperhdr}/share/hyperhdr/bin/hyperhdr";
      ExecStartPost = "${hyperhdrAudioRoute}";
      Restart = "on-failure";
      RestartSec = "2s";
      Environment = [
        "HYPERHDR_PLAYBACK_NODE=easyeffects_sink"
      ];
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.hyperhdr-audio-route = {
    Unit = {
      Description = "Route playback audio into HyperHDR music effects";
      After = [ "hyperhdr.service" "pipewire.service" "pipewire-pulse.service" "wireplumber.service" ];
      Wants = [ "hyperhdr.service" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${hyperhdrAudioRoute}";
      Environment = [
        "HYPERHDR_PLAYBACK_NODE=easyeffects_sink"
      ];
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
