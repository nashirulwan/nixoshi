{ config, lib, pkgs, ... }:

{
  # Docker - dipakai buat Hermes Agent (Seraphine), ~/hermes-agent
  virtualisation.docker.enable = true;

  # Jangan sleep saat lid ditutup kalau charger nyambung, biar Seraphine tetap online.
  # Saat pakai baterai, behavior default (suspend) tetap berlaku.
  services.logind.settings.Login = {
    HandleLidSwitchExternalPower = "ignore";
  };
}
