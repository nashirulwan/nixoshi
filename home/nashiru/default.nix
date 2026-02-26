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

    # Python + Jupyter + Data Viz stack
    (python312.withPackages (ps: with ps; [
      jupyterlab
      ipykernel
      matplotlib
      seaborn
      pandas
      numpy
    ]))
  ];
  
  # Import user modules
  imports = [
    inputs.illogical-flake.homeManagerModules.default
    ./shell/fish.nix
    ./programs/git.nix
    ./programs/yazi.nix
    ./theme.nix
  ];

  programs.illogical-impulse.enable = true;
  
  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
