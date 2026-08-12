{ ... }:

{
  imports = [
    ./desktop/mango.nix
    ./desktop/niri.nix
    ./desktop/fonts.nix
    ./desktop/pipewire.nix
    ./programs/fish.nix
    ./programs/steam.nix
    ./programs/default.nix
    ./system/bluetooth.nix
    ./system/nix.nix
    ./system/virtualisation.nix
  ];
}
