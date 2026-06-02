{ config, lib, pkgs, ... }:

{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    extraConfig.pipewire."10-rates"."context.properties" = {
      "default.clock.rate" = 48000;
      "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 352800 384000 ];
    };
    extraConfig.pipewire."10-resample"."stream.properties" = {
      "resample.quality" = 10;
    };
  };

  environment.systemPackages = with pkgs; [
    pavucontrol
    wireplumber
  ];
}
