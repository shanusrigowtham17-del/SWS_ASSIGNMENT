#!/usr/bin/env bash
# Shared storage and validation functions. CSV fields cannot contain commas.
DATA_DIR="${TRANSPORT_DATA_DIR:-$SCRIPT_DIR/data}"
SERVICES="$DATA_DIR/services.csv"
DELAYS="$DATA_DIR/delays.csv"

init_data() {
    mkdir -p "$DATA_DIR" || return 1
    if [[ ! -f "$SERVICES" ]]; then
        cat <<'EOF' > "$SERVICES" || return 1
id,type,origin,destination,departure,arrival
B101,Bus,Kakinada,Rajahmundry,08:00,09:30
B102,Bus,Kakinada,Samalkot,09:15,10:00
T201,Train,Samalkot,Visakhapatnam,10:30,13:00
B103,Bus,Rajahmundry,Kakinada,17:00,18:30
T202,Train,Visakhapatnam,Samalkot,23:30,02:00
EOF
    fi
    if [[ ! -f "$DELAYS" ]]; then
        cat <<'EOF' > "$DELAYS" || return 1
service_date,id,delay_minutes,reason,recorded_at,type,origin,destination,departure,arrival
EOF
    fi
}

valid_text() {
    [[ -n "$1" && "$1" == *[![:space:]]* && "$1" != *','* && "$1" != *$'\n'* && "$1" != *$'\r'* && "$1" != *$'\t'* ]]
}

valid_time() {
    [[ "$1" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]
}

service_exists() {
    awk -F, -v id="$1" 'NR > 1 && $1 == id {found=1} END {exit !found}' "$SERVICES"
}

get_service() {
    awk -F, -v id="$1" 'NR > 1 && $1 == id {print; exit}' "$SERVICES"
}

print_services() {
    awk -F, 'BEGIN {printf "%-10s %-8s %-22s %-22s %-10s %-10s\n", "ID", "Type", "Origin", "Destination", "Departure", "Arrival"}
        {printf "%-10s %-8s %-22s %-22s %-10s %-10s\n", $1,$2,$3,$4,$5,$6; n++}
        END {if (!n) print "No matching services."}'
}

add_service() {
    local id kind origin destination departure arrival
    read -r -p "Unique service ID (letters, digits, - or _): " id || return 1
    if [[ ! "$id" =~ ^[[:alnum:]][[:alnum:]_-]*$ ]] || service_exists "$id"; then
        echo "Invalid or duplicate service ID."; return 1
    fi
    read -r -p "Type (Bus/Train/Metro): " kind || return 1
    case "$kind" in Bus|Train|Metro) ;; *) echo "Choose Bus, Train or Metro."; return 1 ;; esac
    read -r -p "Origin: " origin || return 1
    read -r -p "Destination: " destination || return 1
    if ! valid_text "$origin" || ! valid_text "$destination"; then
        echo "Use nonempty place names without commas or control characters."; return 1
    fi
    read -r -p "Departure (HH:MM, 24-hour): " departure || return 1
    read -r -p "Arrival (HH:MM, 24-hour): " arrival || return 1
    if ! valid_time "$departure" || ! valid_time "$arrival"; then
        echo "Invalid time. Example: 09:05."; return 1
    fi
    printf '%s,%s,%s,%s,%s,%s\n' "$id" "$kind" "$origin" "$destination" "$departure" "$arrival" >> "$SERVICES" || return 1
    echo "Service $id added."
}

remove_service() {
    local id answer tmp
    read -r -p "Service ID to remove: " id || return 1
    if ! service_exists "$id"; then echo "Service not found."; return 1; fi
    read -r -p "Remove $id? (y/N): " answer || return 1
    [[ "$answer" == y || "$answer" == Y ]] || { echo "Cancelled."; return 0; }
    tmp=$(mktemp "$DATA_DIR/services.XXXXXX") || return 1
    if awk -F, -v id="$id" 'NR == 1 || $1 != id' "$SERVICES" > "$tmp" && mv "$tmp" "$SERVICES"; then
        echo "Service removed. Historical delay records are retained."
    else
        rm -f "$tmp"; return 1
    fi
}
