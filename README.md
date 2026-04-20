# nixoshi

Personal NixOS flake for `nixoshi`.

This configuration currently targets a Niri + Noctalia desktop setup with HyperHDR ambient lighting support.

## Desktop Stack

- NixOS unstable flake
- Home Manager for user configuration
- Niri Wayland compositor
- Noctalia Shell for bar, launcher, widgets, wallpaper, and theming
- SDDM with the `pixel-coffee` QML theme
- PipeWire, WirePlumber, and PulseAudio compatibility
- HyperHDR for monitor and music-reactive ambient lighting

## Important Paths

- NixOS host entry: `hosts/nixoshi/default.nix`
- Desktop module: `modules/desktop/niri.nix`
- User Home Manager config: `home/nashiru/default.nix`
- Niri config and keybinds: `home/nashiru/niri/config.kdl`
- Noctalia mutable settings: `home/nashiru/noctalia-settings.mutable.json`
- SDDM theme assets: `assets/sddm-themes/qylock/pixel-coffee/`

The active Niri config is managed by Home Manager at:

```bash
~/.config/niri/config.kdl
```

## Rebuild

Apply the system configuration with:

```bash
cd ~/nixoshi
sudo nixos-rebuild switch --flake .#nixoshi
```

Validate the Niri config before rebuilding:

```bash
niri validate -c ~/nixoshi/home/nashiru/niri/config.kdl
```

## Niri Keybinds

Keybinds are declared in:

```bash
home/nashiru/niri/config.kdl
```

Common bindings:

```kdl
Mod+Return { spawn "kitty"; }
Mod+T { spawn "kitty"; }
Mod+W { spawn "zen"; }
Mod+E { spawn "nautilus"; }
Mod+Q { close-window; }
Mod+F { fullscreen-window; }
Mod+Shift+F { toggle-window-floating; }
Mod+Space { spawn "noctalia-shell" "ipc" "call" "launcher" "toggle"; }
Print { screenshot; }
```

Reload Niri after editing the active config:

```bash
niri msg action reload-config
```

## HyperHDR

HyperHDR is launched as a Niri session application via `hyperhdr-session`.

This is intentional: HyperHDR's PipeWire/portal software screen capture needs to run as a desktop application, not as a background daemon service.

Relevant helpers:

```bash
hyperhdr-session
hyperhdr-monitor
hyperhdr-music
```

The current LED controller setup uses:

- Device type: `adalight`
- Output: `ttyUSB0`
- Baud rate: `115200`
- Protocol mode: classic Adalight (`awa_mode = false`)

HyperHDR stores runtime settings in:

```bash
~/.hyperhdr/db/hyperhdr.db
```

That database is not part of this repository. Back it up separately if needed:

```bash
cp ~/.hyperhdr/db/hyperhdr.db ~/hyperhdr.db.backup
```

If the LED controller stops responding after unplugging/replugging the laptop, restart HyperHDR:

```bash
pkill hyperhdr
rm -f /tmp/LCK..ttyUSB0
niri msg action spawn -- hyperhdr-session
```

Then re-enable the monitor grabber:

```bash
curl -fsS http://127.0.0.1:8090/json-rpc \
  -H 'Content-Type: application/json' \
  -d '{"command":"componentstate","componentstate":{"component":"SYSTEMGRABBER","state":true}}'
```

## Branch Notes

The Niri, Noctalia, and HyperHDR migration work is on:

```bash
niri-noctalia-hyperhdr
```

Merge or push this branch to `main` when it is ready to become the default GitHub view.
