{ config, lib, pkgs, ... }:

{
  # PipeWire audio server (modern replacement for PulseAudio)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;  # For 32-bit games
    pulse.enable = true;        # PulseAudio compatibility
  };
  
  # Audio control tools
  environment.systemPackages = with pkgs; [
    pavucontrol   # GUI for PulseAudio/PipeWire
    wireplumber   # Session manager for PipeWire
  ];
}
