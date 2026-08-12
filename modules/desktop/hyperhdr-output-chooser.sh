#!/usr/bin/env bash
set -euo pipefail

wlr_randr_cmd="${WLR_RANDR_CMD:-wlr-randr}"
preferred_output="${HYPERHDR_PREFERRED_OUTPUT:-}"
outputs="$("$wlr_randr_cmd" 2>/dev/null || true)"

output_enabled() {
  local output_name=$1

  printf '%s\n' "$outputs" | awk -v target="$output_name" '
    $1 == target { in_output = 1; next }
    in_output && $0 !~ /^[[:space:]]/ { in_output = 0 }
    in_output && $0 ~ /^[[:space:]]+Enabled: yes/ { found = 1 }
    END { exit(found ? 0 : 1) }
  '
}

# Honor an explicit consumer preference when that output is enabled.
if [[ -n "$preferred_output" ]] && output_enabled "$preferred_output"; then
  printf 'Monitor: %s\n' "$preferred_output"
  exit 0
fi

# Otherwise select the first enabled output in wlr-randr order.
first_enabled=$(printf '%s\n' "$outputs" | awk '
  /^[^[:space:]]/ { output_name = $1; next }
  output_name != "" && /^[[:space:]]+Enabled: yes/ { print output_name; exit }
')

[[ -n "$first_enabled" ]] || exit 1
printf 'Monitor: %s\n' "$first_enabled"
