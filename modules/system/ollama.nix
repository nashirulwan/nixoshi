{ config, lib, pkgs, ... }:

{
  # Enable Ollama service
  services.ollama = {
    enable = true;
    # Auto-download and load models on startup
    # gemma4:26b - heavy coding tasks
    # gemma4:9b - lightweight/scripting tasks
    loadModels = [ "gemma4:26b" "gemma4:9b" ];
  };
}
