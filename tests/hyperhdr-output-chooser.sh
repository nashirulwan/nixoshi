#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
chooser="$repo_root/modules/desktop/hyperhdr-output-chooser.sh"
desktop_module="$repo_root/modules/desktop/mango.nix"
home_module="$repo_root/home/default.nix"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

write_wlr_randr() {
  local body=$1
  printf '#!/usr/bin/env bash\nprintf %%s %q\n' "$body" > "$tmp_dir/wlr-randr"
  chmod +x "$tmp_dir/wlr-randr"
}

assert_output() {
  local name=$1
  local expected=$2
  local body=$3
  local preferred=${4-}
  write_wlr_randr "$body"
  local actual
  if [[ -n "$preferred" ]]; then
    actual=$(HYPERHDR_PREFERRED_OUTPUT="$preferred" WLR_RANDR_CMD="$tmp_dir/wlr-randr" "$chooser")
  else
    actual=$(env -u HYPERHDR_PREFERRED_OUTPUT WLR_RANDR_CMD="$tmp_dir/wlr-randr" "$chooser")
  fi
  if [[ "$actual" != "$expected" ]]; then
    printf 'FAIL %s: expected %q, got %q\n' "$name" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_no_output() {
  local body=$1
  write_wlr_randr "$body"
  if env -u HYPERHDR_PREFERRED_OUTPUT WLR_RANDR_CMD="$tmp_dir/wlr-randr" "$chooser" >/dev/null 2>&1; then
    printf 'FAIL no-output case: chooser unexpectedly succeeded\n' >&2
    exit 1
  fi
}

outputs=$'Virtual-1 "Built-in display"\n  Enabled: no\nDock-2 "Desk display"\n  Enabled: yes\nProjector-7 "Room display"\n  Enabled: yes\n'
assert_output "first enabled fallback" "Monitor: Dock-2" "$outputs"
assert_output "preferred enabled output" "Monitor: Projector-7" "$outputs" "Projector-7"
assert_output "disabled preference falls back" "Monitor: Dock-2" "$outputs" "Virtual-1"
assert_no_output $'Virtual-1\n  Enabled: no\nDock-2\n  Enabled: no\n'

grep -q 'chooser_type = "simple"' "$desktop_module"
! grep -q 'output_name' "$desktop_module"

portal_line=$(grep -n 'restart xdg-desktop-portal-wlr.service' "$home_module" | head -n1 | cut -d: -f1 || true)
hyperhdr_line=$(grep -n 'restart hyperhdr.service' "$home_module" | head -n1 | cut -d: -f1 || true)
[[ -n "$portal_line" && -n "$hyperhdr_line" && "$portal_line" -lt "$hyperhdr_line" ]]
grep -q 'server_ready' "$home_module"

printf 'PASS HyperHDR output chooser and sync wiring\n'
