{ pkgs, ... }:

{
  # Enable BlueZ stack and auto-power controller on boot
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # GUI tray/controller for desktop pairing
  services.blueman.enable = true;

  # Ensure CLI tool is available (bluetoothctl)
  environment.systemPackages = with pkgs; [
    bluez
  ];
}
