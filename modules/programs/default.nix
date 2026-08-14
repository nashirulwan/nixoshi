{ config, lib, pkgs, inputs, ... }:

let
  compatPkgs = import inputs.nixpkgs-mpv-compat {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  feishinMpv = lib.hiPrio compatPkgs.mpv;
in
{
  # Core system packages
  environment.systemPackages = with pkgs; [
    # Editors
    vim
    neovim

    # Terminals
    kitty
    foot

    # Essential tools
    git
    wget
    curl
    tree
    jq

    # File manager
    nautilus

    # Dependencies for File Manager
    gvfs

    # Browsers
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Media & Communication
    zoom-us
    feishin

    # Development
    nodejs_22
    zed-editor

    # Utilities
    polkit_gnome
    pear-desktop
    antigravity
    davinci-resolve

    # Theme & Network Dependencies
    glib-networking
    gnome-themes-extra
    adwaita-icon-theme
    gsettings-desktop-schemas

    # GNOME apps
    loupe              # image viewer
    krita              # image editor
    gnome-calculator   # kalkulator
    gnome-text-editor  # text editor
    sushi              # quick preview in nautilus (press space)
    papers             # pdf / document viewer
    gnome-clocks       # clock, alarm, timer, stopwatch
    gnome-calendar     # calendar
    gnome-weather      # weather
    snapshot           # camera (webcam)

    # Live wallpaper video (.mp4)
    mpvpaper

    # Archives
    zip
    unzip
    _7zz
    file-roller

    # Multimedia & Office (User additions)
    yt-dlp
    feishinMpv
    smplayer
    obs-studio
    xwayland-run
    libreoffice
    hunspellDicts.en_US
    hyphenDicts.en-us
    feh
    gh
    home-manager
    hyperhdr
    prismlauncher
    brave

    # CLI tools (fd & ripgrep also power Yazi's file/content search)
    fd
    ripgrep
    fzf
    bat
    eza

    opencode
    opencode-desktop
  ];

  # GPU screen recorder
  programs.gpu-screen-recorder.enable = true;

  # Nautilus dependencies
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.udisks2.enable = true;
  programs.dconf.enable = true;
}
