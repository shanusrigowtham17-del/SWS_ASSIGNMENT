#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
export TRANSPORT_DATA_DIR="$WORK/data"
source "$ROOT/Transport_Tracker/main.sh"
for file in "$ROOT"/Transport_Tracker/*.sh; do bash -n "$file"; done
init_data
[[ $(wc -l < "$SERVICES") -eq 6 ]]
valid_time 23:59
! valid_time 24:00
! valid_time 9:00
! valid_text 'Bad,place'
! valid_text '   '
view_status > "$WORK/status"
grep -q 'No update' "$WORK/status"
printf 'TEST1\nMetro\nAlpha\nBeta\n23:55\n00:10\n' | add_service
service_exists TEST1
if printf 'TEST1\n' | add_service; then exit 1; fi
if printf 'BAD\nBus\nAlpha\nBeta\n25:00\n12:00\n' | add_service; then exit 1; fi
printf 'alpha\n' | search_timetable > "$WORK/search"
grep -q TEST1 "$WORK/search"
printf '[\n' | search_timetable > "$WORK/search"
grep -q 'No matching services' "$WORK/search"
printf 'TEST1\n20\nTraffic\n' | record_delay
view_status > "$WORK/status"
grep -q '00:30 (+1d)' "$WORK/status"
printf 'TEST1\n08\nRoad work\n' | record_delay
[[ $(wc -l < "$DELAYS") -eq 2 ]]
grep -q 'TEST1,8,Road work' "$DELAYS"
if printf 'TEST1\n1441\n' | record_delay; then exit 1; fi
if printf 'TEST1\n-1\n' | record_delay; then exit 1; fi
printf 'B101\n0\nOn time\n' | record_delay
write_report > "$WORK/report"
grep -q 'Observations (all dates): 2' "$WORK/report"
grep -q 'Average delay across all observations: 4.00' "$WORK/report"
printf 'TEST1\ny\n' | remove_service
! service_exists TEST1
printf 'TEST1\n' | view_history > "$WORK/history"
grep -q Alpha "$WORK/history"
generate_report > "$WORK/saved"
[[ -n $(ls "$DATA_DIR/reports/") ]]
# A fresh process can read the saved data; menu handles invalid input and exits.
printf '9\n1\n0\n' | bash "$ROOT/Transport_Tracker/main.sh" > "$WORK/menu"
grep -q 'Invalid choice' "$WORK/menu"
grep -q 'Goodbye' "$WORK/menu"
[[ ! -d "$DATA_DIR/.session_lock" ]]
mkdir "$DATA_DIR/.session_lock"
if printf '0\n' | bash "$ROOT/Transport_Tracker/main.sh" > "$WORK/lock"; then exit 1; fi
grep -q 'Another session' "$WORK/lock"
rmdir "$DATA_DIR/.session_lock"
echo 'PASS: syntax, validation, search, persistence, delays, rollover, history, reports, menu and lock'
