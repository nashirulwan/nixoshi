{ config, lib, pkgs, inputs, ... }:

let
  qylockPixelCoffee = pkgs.stdenvNoCC.mkDerivation {
    pname = "sddm-qylock-pixel-coffee";
    version = "2026-04-20";
    src = ../../assets/sddm-themes/qylock/pixel-coffee;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/sddm/themes/pixel-coffee
      cp -r . $out/share/sddm/themes/pixel-coffee
      runHook postInstall
    '';
  };
in
{
  # Niri Wayland compositor.
  programs.niri = {
    enable = true;
    useNautilus = true;
  };

  # Keep the current D-Bus implementation so nixos-rebuild switch is not
  # blocked by a broker -> dbus critical component change.
  services.dbus.implementation = "broker";

  services.displayManager.defaultSession = "niri";

  # SDDM display manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "pixel-coffee";
    package = pkgs.kdePackages.sddm;
    extraPackages =
      (with pkgs.kdePackages; [
        qylockPixelCoffee
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

  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };

  # Touchpad support for laptops
  services.libinput.enable = true;

  # Session services commonly expected by Niri setups.
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

  # Session services commonly used by Noctalia widgets and laptop controls.
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
    qylockPixelCoffee
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
