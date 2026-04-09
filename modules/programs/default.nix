{ config, lib, pkgs, inputs, ... }:

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
    
    # File manager
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
    nodePackages.npm
    
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
    
    # Archives
    zip
    unzip
    _7zz
    file-roller
    
    # Multimedia & Office (User additions)
    yt-dlp
    mpv
    smplayer
    libreoffice
    feh
  ];
  
  # GPU screen recorder
  programs.gpu-screen-recorder.enable = true;

  # Nautilus dependencies
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.udisks2.enable = true;
  programs.dconf.enable = true;
}
