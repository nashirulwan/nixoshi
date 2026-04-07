{ config, pkgs, inputs, ... }:

{
  # Home Manager version
  home.stateVersion = "25.11";
  
  # User information
  home.username = "nashiru";
  home.homeDirectory = "/home/nashiru";
  
  home.packages = with pkgs; [
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
  ];

  programs.illogical-impulse.enable = true;
  
  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
