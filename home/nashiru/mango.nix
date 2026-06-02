{ config, lib, pkgs, inputs, ... }:

let
  mangoPackage = inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.mango;

  # Toggle the laptop output (eDP-1) fully on/off via wlr-randr.
  mangoToggleEdp = pkgs.writeShellScriptBin "mango-toggle-edp" ''
    if ${pkgs.wlr-randr}/bin/wlr-randr | ${pkgs.gnugrep}/bin/grep -A40 '^eDP-1' \
        | ${pkgs.gnugrep}/bin/grep -m1 -q 'Enabled: yes'; then
      ${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --off
    else
      ${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --on
    fi

    # Toggling an output resets the screencast stream HyperHDR captures, so
    # re-run the sync once the layout settles to restore screen capture.
    ${pkgs.systemd}/bin/systemctl --user start hyperhdr-startup-sync.service &
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
    mangoToggleEdp
    (lib.hiPrio mmsgWrapper)  # take priority over mango's bundled mmsg
  ];

  # Overwrite config.conf without a backup (avoids the "would be clobbered" error).
  xdg.configFile."mango/config.conf".force = true;

  wayland.windowManager.mango = {
    enable = true;
    extraConfig = builtins.readFile ./mango/config.conf;
    autostart_sh = ''
      mkdir -p "$HOME/Pictures/Screenshots"
      noctalia-shell &
      sleep 3 && systemctl --user restart xdg-desktop-portal-wlr.service &
    '';
  };
}
