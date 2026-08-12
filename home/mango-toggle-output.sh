#!/usr/bin/env bash
set -euo pipefail

target="${MANGO_TOGGLE_OUTPUT:-}"
wlr_randr_cmd="${WLR_RANDR_CMD:-wlr-randr}"
systemctl_cmd="${SYSTEMCTL_CMD:-systemctl}"

if [[ -z "$target" ]]; then
  printf 'MANGO_TOGGLE_OUTPUT is unset; no output was toggled.\n' >&2
  exit 0
fi

outputs=$("$wlr_randr_cmd")
if printf '%s\n' "$outputs" | awk -v target="$target" '
  $1 == target { in_output = 1; next }
  in_output && $0 !~ /^[[:space:]]/ { in_output = 0 }
  in_output && $0 ~ /^[[:space:]]+Enabled: yes/ { found = 1 }
  END { exit(found ? 0 : 1) }
'; then
  "$wlr_randr_cmd" --output "$target" --off
else
  "$wlr_randr_cmd" --output "$target" --on
fi

"$systemctl_cmd" --user start --no-block hyperhdr-startup-sync.service
