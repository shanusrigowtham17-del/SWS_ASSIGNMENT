#!/usr/bin/env bash
# Timetable operations use awk and sort from the scripting workshop.
view_timetable() {
    echo "Daily timetable (local time; arrival before departure means next day)"
    tail -n +2 "$SERVICES" | sort -t, -k5,5 -k1,1 | print_services
}

search_timetable() {
    local query
    read -r -p "Search ID, type, origin or destination: " query || return 1
    if ! valid_text "$query"; then echo "Enter a valid search term."; return 1; fi
    # Literal case-insensitive substring search, so regex characters are safe.
    awk -F, -v q="$query" 'NR > 1 && index(tolower($1 "," $2 "," $3 "," $4),tolower(q)) {print}' "$SERVICES" |
        sort -t, -k5,5 -k1,1 | print_services
}
