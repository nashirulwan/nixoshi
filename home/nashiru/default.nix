{ config, pkgs, ... }:

{
  # Home Manager version
  home.stateVersion = "25.11";
  
  # User information
  home.username = "nashiru";
  home.homeDirectory = "/home/nashiru";
  
  # Import user modules
  imports = [
    ./shell/fish.nix
    ./programs/git.nix
    ./programs/yazi.nix
    ./theme.nix
  ];
  
  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
