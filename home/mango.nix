{ config, lib, pkgs, inputs, mangoOutput ? null, ... }:

let
  mangoPackage = inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.mango;

  mangoToggleOutput = pkgs.writeShellScriptBin "mango-toggle-output" ''
    ${lib.optionalString (mangoOutput != null)
      "export MANGO_TOGGLE_OUTPUT=${lib.escapeShellArg mangoOutput}"}
    export WLR_RANDR_CMD="${pkgs.wlr-randr}/bin/wlr-randr"
    export SYSTEMCTL_CMD="${pkgs.systemd}/bin/systemctl"
    exec ${pkgs.bash}/bin/bash ${./mango-toggle-output.sh}
  '';

  # Noctalia calls "mmsg -s -d CMD" but mmsg only knows "mmsg dispatch CMD".
  # Translate the old syntax, then call the real mmsg from the nix store.
  mmsgWrapper = pkgs.writeShellScriptBin "mmsg" ''
    args=()
    for arg in "$@"; do
      case "$arg" in
        -s) ;;                            # drop (noctalia passes -s with no socket)
        -d) args+=("dispatch") ;;
        -q) args+=("dispatch" "quit") ;;
        *)  args+=("$arg") ;;
      esac
    done
    exec "${mangoPackage}/bin/mmsg" "''${args[@]}"
  '';
in
{
  home.packages = [
    pkgs.wlr-randr
    mangoToggleOutput
    (lib.hiPrio mmsgWrapper)  # take priority over mango's bundled mmsg
  ];

  # Overwrite config.conf without a backup (avoids the "would be clobbered" error).
  xdg.configFile."mango/config.conf".force = true;

  wayland.windowManager.mango = {
    enable = true;
    extraConfig = builtins.readFile ./mango/config.conf;
    autostart_sh = ''
      mkdir -p "$HOME/Pictures/Screenshots"
      # Export WAYLAND_DISPLAY so systemd user services can connect to compositor
      systemctl --user import-environment WAYLAND_DISPLAY DISPLAY XAUTHORITY 2>/dev/null || true
      noctalia-shell &
      sleep 3 && systemctl --user restart xdg-desktop-portal-wlr.service &
    '';
  };
}
