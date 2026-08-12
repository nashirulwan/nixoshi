{ config, lib, pkgs, ... }:

{
  # Steam gaming platform
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;      # Steam Remote Play
    dedicatedServer.openFirewall = true; # Source Dedicated Server
    gamescopeSession.enable = true;      # Gamescope compositor
  };
  
  # GameMode for performance optimization
  programs.gamemode.enable = true;
  
  # Gaming tools and utilities
  environment.systemPackages = with pkgs; [
    mangohud       # Performance overlay
    steam-run      # Run non-NixOS binaries
    protonup-qt    # Proton version manager
  ];
  
}
