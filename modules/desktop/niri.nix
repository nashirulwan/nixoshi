{ config, lib, pkgs, inputs, ... }:

let
  qylockSword = pkgs.stdenvNoCC.mkDerivation {
    pname = "sddm-qylock-sword";
    version = "2026-06-02";
    src = ../../assets/sddm-themes/qylock/sword;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/sddm/themes/sword
      cp -r . $out/share/sddm/themes/sword
      runHook postInstall
    '';
  };
in
{
  programs.niri = {
    enable = true;
    useNautilus = true;
  };

  services.dbus.implementation = "broker";

  services.displayManager.defaultSession = "niri";

  # X server masih dibutuhkan SDDM (login manager). 
  # Bisa di-disable kalau SDDM udah pakai Wayland mode.
  services.xserver.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
    theme = "sword";
    package = pkgs.kdePackages.sddm;
    extraPackages =
      (with pkgs.kdePackages; [
        qylockSword
        qt5compat
        qtsvg
        qtmultimedia
      ])
      ++ (with pkgs.gst_all_1; [
        gst-plugins-base
        gst-plugins-good
        gst-plugins-bad
        gst-plugins-ugly
        gst-libav
      ]);
  };

  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xrandr}/bin/xrandr --output HDMI-A-1 --auto --primary || true
  '';

  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };

  services.libinput.enable = true;

  services.gnome.gnome-keyring.enable = true;
  services.gnome.gcr-ssh-agent.enable = false;
  security.pam.services.swaylock = {};

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  xdg.portal = {
    enable = true;
    config.niri = {
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  services.geoclue2.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;

  environment.systemPackages = (with pkgs; [
    alacritty
    btop
    brightnessctl
    cava
    cliphist
    foot
    fuzzel
    grim
    imagemagick
    inotify-tools
    networkmanager_dmenu
    pamixer
    playerctl
    pulseaudio
    pwvucontrol
    python3
    rofi
    slurp
    swayidle
    swaylock
    wlsunset
    wl-clipboard
    wl-screenrec
    wmenu
    xwayland-satellite
  ]) ++ [
    qylockSword
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
