{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    # Hardware scan results
    ./hardware-configuration.nix

    # System modules
    ../../modules/system/boot.nix
    ../../modules/system/networking.nix
    ../../modules/system/locale.nix
    ../../modules/system/security.nix
    ../../modules/system/bluetooth.nix
    ../../modules/system/nix.nix
    ../../modules/system/virtualisation.nix

    # Desktop modules
    ../../modules/desktop/niri.nix
    ../../modules/desktop/mango.nix
    ../../modules/desktop/fonts.nix
    ../../modules/desktop/pipewire.nix
    
    # Program modules
    ../../modules/programs/fish.nix
    ../../modules/programs/steam.nix
    ../../modules/programs/default.nix
  ];
  
  # User account definition
  users.users.nashiru = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "dialout" "uucp" "input" ];
    shell = pkgs.fish;
    packages = with pkgs; [ tree ];
  };

  # DaVinci Resolve needs an OpenCL runtime for AMD GPUs.
  hardware.amdgpu.opencl.enable = true;
  
  # GPU support (needed by Steam, DaVinci Resolve, HyperHDR, etc.)
  hardware.graphics.enable = true;
  
  # NixOS state version
  # DO NOT CHANGE - see manual for details
  system.stateVersion = "25.11";
}
