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
    nautilus
    
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
    
    # Multimedia & Office (User additions)
    yt-dlp
    mpv
    smplayer
    libreoffice
    feh
  ];
  
  # GPU screen recorder
  programs.gpu-screen-recorder.enable = true;
}
