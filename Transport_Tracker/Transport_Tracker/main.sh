#!/usr/bin/env bash
# Main menu and module loading. Compatible with Bash 3.2+.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/data_manager.sh"
source "$SCRIPT_DIR/timetable.sh"
source "$SCRIPT_DIR/delay_tracker.sh"
source "$SCRIPT_DIR/reports.sh"

main() {
    init_data || return 1
    # One interactive session per data directory prevents conflicting writes.
    if ! mkdir "$DATA_DIR/.session_lock" 2>/dev/null; then
        echo "Another session is using this data directory."
        echo "If a session was forcibly stopped, remove $DATA_DIR/.session_lock."
        return 1
    fi
    trap 'rmdir "$DATA_DIR/.session_lock" 2>/dev/null' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    local choice
    while true; do
        cat <<'MENU'

PUBLIC TRANSPORT TIMETABLE AND DELAY TRACKER
1. View timetable
2. Search timetable
3. Add service
4. Remove service
5. Record or update today's delay
6. View today's service status
7. View delay history
8. Generate summary report
0. Exit
MENU
        read -r -p "Choose: " choice || break
        case "$choice" in
            1) view_timetable ;;
            2) search_timetable ;;
            3) add_service ;;
            4) remove_service ;;
            5) record_delay ;;
            6) view_status ;;
            7) view_history ;;
            8) generate_report ;;
            0) echo "Goodbye!"; break ;;
            *) echo "Invalid choice. Enter 0 to 8." ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
