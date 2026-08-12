# NixOS rice with Mango + Noctalia

Reusable NixOS and Home Manager modules for a Wayland desktop built around
[Mango](https://github.com/mangowm/mango), [Niri](https://github.com/YaLTeR/niri),
and [Noctalia](https://github.com/noctalia-dev/noctalia-shell).

![Desktop](assets/screenshots/desktop.png)

|  |  |
|--|--|
| ![Launcher](assets/screenshots/launcher.png) | ![Blur](assets/screenshots/blur.png) |
| ![SDDM](assets/screenshots/sddm.png) | ![Fastfetch](assets/screenshots/fastfetch.png) |

### Components

| Component | Software | Config |
|-----------|----------|--------|
| Compositor | [Mango](https://github.com/mangowm/mango) | [`mango/config.conf`](home/mango/config.conf) |
| Shell / Bar | [Noctalia](https://github.com/noctalia-dev/noctalia-shell) | [`noctalia-settings.mutable.json`](home/noctalia-settings.mutable.json) |
| Login | [SDDM](https://github.com/sddm/sddm) · [`sword` theme](https://github.com/Darkkal44/qylock) | [`assets/sddm-themes/qylock/sword`](assets/sddm-themes/qylock/sword) |
| Terminal | [kitty](https://sw.kovidgoyal.net/kitty/) | [`programs/kitty.nix`](home/programs/kitty.nix) |
| Shell | [fish](https://fishshell.com/) | [`shell/fish.nix`](home/shell/fish.nix) |
| Files | [yazi](https://github.com/sxyazi/yazi) | [`programs/yazi.nix`](home/programs/yazi.nix) |
| Theming | matugen (via Noctalia) | [`theme.nix`](home/theme.nix) |

### Use the modules

The flake exports `nixosModules.default` and `homeManagerModules.default`. The
[example flake](examples/flake.nix) is a complete minimal Home Manager consumer.
Set `home.username` and `home.homeDirectory` in the consuming configuration;
the public module deliberately does not choose an account identity.

Noctalia's writable settings default to
`~/.local/state/nixoshi/noctalia-settings.json`. To keep an existing mutable
file elsewhere, pass an absolute `nixoshiSettingsFile` through Home Manager's
`extraSpecialArgs`.

The generic desktop has no fixed output topology. Consumers can optionally set:

- `MANGO_TOGGLE_OUTPUT` to make `Super+Alt+O` toggle one named output.
- `HYPERHDR_PREFERRED_OUTPUT` to prefer one enabled output for HyperHDR capture;
  without it, the chooser selects the first enabled output reported by
  `wlr-randr`.

The Fish aliases `rebuild`, `rebuild-test`, `update`, and `dotfiles-status` are
only added when the consumer passes `privateRoot` through `extraSpecialArgs`.
The value should be the absolute path of the consumer's deployment flake.


### Wallpapers

- Desktop wallpapers: [wallpaperflare.com](https://www.wallpaperflare.com/)
- SDDM Wallpaper: [wallsflow.com](https://wallsflow.com/live-wallpapers/anime/887-anime-girl-sword-blue-eyes-live-wallpaper.html)
