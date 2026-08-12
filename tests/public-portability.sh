#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

[[ -f home/default.nix ]] || fail "generic Home Manager module path is missing"
[[ ! -d home/nashiru ]] || fail "identity-specific Home Manager directory remains"

mapfile -d '' -t active_sources < <(
  git ls-files -z -- '*.nix' '*.json' '*.conf' '*.kdl' '*.sh' ':(exclude)tests/**'
)
[[ ${#active_sources[@]} -gt 0 ]] || fail "no active public sources were discovered"

policy_sources=("${active_sources[@]}" README.md CONTRIBUTING.md)
prohibited='(/home/nashiru|nixoshi-private|HDMI-A-1|eDP-1|1920x1080|width:1920|height:1080|refresh:200|Jakarta|Indonesia|nashirulwan@users\.noreply\.github\.com)'
if rg -n "$prohibited" "${policy_sources[@]}"; then
  fail "private identity, path, or display topology remains in the active public tree"
fi

if rg -n '^\s*home\.(username|homeDirectory)\s*=' home/default.nix; then
  fail "the exported Home Manager module sets consumer identity"
fi

if rg -n '^\s*(name|email)\s*=' home/programs/git.nix; then
  fail "the public Git module sets identity"
fi

if rg -n 'monitorrule=' home/mango/config.conf; then
  fail "Mango contains a fixed monitor rule"
fi

if rg -n 'setupCommands|xrandr[^\n]*--output' modules/desktop/niri.nix; then
  fail "Niri contains an XRandR output setup command"
fi

if rg -n '^output\s+"' home/niri/config.kdl; then
  fail "generic Niri config contains output blocks"
fi
grep -Fxq 'include "noctalia.kdl"' home/niri/config.kdl \
  || fail "Niri theme include is not consumer-local"

jq -e '.desktopWidgets.monitorWidgets == []' home/noctalia-settings.mutable.json >/dev/null \
  || fail "Noctalia mutable defaults remain monitor-specific"
jq -e '.location.name == "" and .location.weatherEnabled == false' \
  home/noctalia-settings.mutable.json >/dev/null \
  || fail "Noctalia mutable defaults contain a fixed weather location"

location_block=$(awk '
  /^      location = \{/ { capture = 1 }
  capture { print }
  capture && /^      \};/ { exit }
' home/default.nix)
[[ -n "$location_block" ]] || fail "Noctalia location defaults are missing"
if rg -n '^\s*name\s*=' <<<"$location_block"; then
  fail "the Home Manager module contains a fixed location name"
fi
grep -q '^\s*weatherEnabled = false;' <<<"$location_block" \
  || fail "portable Noctalia weather is not disabled by default"

rg -q 'privateRoot \? null' home/shell/fish.nix \
  || fail "Fish does not expose the optional privateRoot argument"
rg -q 'nixoshiSettingsFile \? null' home/default.nix \
  || fail "Home Manager no longer exposes nixoshiSettingsFile"
rg -q 'homeConfigurations\.demo' examples/flake.nix \
  || fail "the example does not instantiate a Home Manager consumer"

printf 'PASS public portability policy\n'
