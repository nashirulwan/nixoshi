#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
toggle="$repo_root/home/mango-toggle-output.sh"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

write_commands() {
  local body=$1
  : > "$tmp_dir/calls"
  cat > "$tmp_dir/wlr-randr" <<SCRIPT
#!/usr/bin/env bash
if [[ \$# -eq 0 ]]; then
  printf '%s' '$body'
else
  printf 'wlr' >> '$tmp_dir/calls'
  printf ' <%s>' "\$@" >> '$tmp_dir/calls'
  printf '\n' >> '$tmp_dir/calls'
fi
SCRIPT
  cat > "$tmp_dir/systemctl" <<SCRIPT
#!/usr/bin/env bash
printf 'systemctl' >> '$tmp_dir/calls'
printf ' <%s>' "\$@" >> '$tmp_dir/calls'
printf '\n' >> '$tmp_dir/calls'
SCRIPT
  chmod +x "$tmp_dir/wlr-randr" "$tmp_dir/systemctl"
}

write_commands ''
message=$(env -u MANGO_TOGGLE_OUTPUT \
  WLR_RANDR_CMD="$tmp_dir/wlr-randr" SYSTEMCTL_CMD="$tmp_dir/systemctl" \
  "$toggle" 2>&1)
[[ "$message" == *"MANGO_TOGGLE_OUTPUT is unset"* ]]
[[ ! -s "$tmp_dir/calls" ]]

write_commands $'Virtual-1\n  Enabled: yes\nProjector-7\n  Enabled: yes\n'
MANGO_TOGGLE_OUTPUT="Projector-7" WLR_RANDR_CMD="$tmp_dir/wlr-randr" \
  SYSTEMCTL_CMD="$tmp_dir/systemctl" "$toggle"
grep -Fxq 'wlr <--output> <Projector-7> <--off>' "$tmp_dir/calls"
grep -Fxq 'systemctl <--user> <start> <--no-block> <hyperhdr-startup-sync.service>' "$tmp_dir/calls"

write_commands $'Virtual-1\n  Enabled: yes\nProjector-7\n  Enabled: no\n'
MANGO_TOGGLE_OUTPUT="Projector-7" WLR_RANDR_CMD="$tmp_dir/wlr-randr" \
  SYSTEMCTL_CMD="$tmp_dir/systemctl" "$toggle"
grep -Fxq 'wlr <--output> <Projector-7> <--on>' "$tmp_dir/calls"

printf 'PASS Mango output toggle\n'
