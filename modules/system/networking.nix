{ config, lib, pkgs, ... }:

{
  # Hostname
  networking.hostName = "nixoshi";
  
  # NetworkManager for WiFi/Ethernet management
  networking.networkmanager.enable = true;
  
  # Tailscale VPN
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };
  
  # Firewall configuration
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    checkReversePath = "loose";
  };
  
  # Don't wait for network on boot (faster startup)
  systemd.network.wait-online.enable = false;
}
