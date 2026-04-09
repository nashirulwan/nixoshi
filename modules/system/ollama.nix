{ config, lib, pkgs, ... }:

{
  # Enable Ollama service
  services.ollama = {
    enable = true;
    # Load gemma4:26b on startup
    models = [ "gemma4:26b" ];
  };
}
