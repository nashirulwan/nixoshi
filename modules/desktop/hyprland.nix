{ config, lib, pkgs, ... }:

{
  # Hyprland Wayland compositor
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  
  # SDDM display manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  
  # Touchpad support for laptops
  services.libinput.enable = true;
  
  # Essential Wayland tools and utilities
  environment.systemPackages = with pkgs; [
    wl-clipboard    # Wayland clipboard utilities
    grim            # Screenshot tool
    slurp           # Region selector
    swaybg          # Wallpaper setter
    rofi            # Application launcher
    brightnessctl   # Brightness control
    playerctl       # Media player control
    wmenu           # Wayland menu
  ];
}
