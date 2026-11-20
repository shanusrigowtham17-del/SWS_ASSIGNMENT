#!/usr/bin/env bash
# Delays are manually entered estimates for the current local service date.
record_delay() {
    local id minutes reason row day stamp tmp
    read -r -p "Service ID: " id || return 1
    if ! service_exists "$id"; then echo "Service not found."; return 1; fi
    read -r -p "Delay in minutes (0 = on time, maximum 1440): " minutes || return 1
    if [[ ! "$minutes" =~ ^[0-9]{1,4}$ ]]; then echo "Enter an integer from 0 to 1440."; return 1; fi
    minutes=$((10#$minutes))
    if (( minutes > 1440 )); then echo "Delay must be 0 to 1440 minutes."; return 1; fi
    read -r -p "Reason (e.g. Traffic / On time): " reason || return 1
    if ! valid_text "$reason"; then echo "Enter a reason without commas or control characters."; return 1; fi
    row=$(get_service "$id") || return 1
    day=$(date +%F)
    stamp=$(date '+%Y-%m-%dT%H:%M:%S%z')
    tmp=$(mktemp "$DATA_DIR/delays.XXXXXX") || return 1
    # Keep one latest observation per service per date, and snapshot its route.
    if awk -F, -v d="$day" -v id="$id" 'NR == 1 || !($1 == d && $2 == id)' "$DELAYS" > "$tmp" &&
        printf '%s,%s,%s,%s,%s,%s\n' "$day" "$id" "$minutes" "$reason" "$stamp" "${row#*,}" >> "$tmp" &&
        mv "$tmp" "$DELAYS"; then
        echo "Delay for $id saved: $minutes minute(s)."
    else
        rm -f "$tmp"; return 1
    fi
}

view_status() {
    echo "Service date: $(date +%F) | Estimated arrivals use the entered delay."
    awk -F, -v today="$(date +%F)" '
        function mins(s, a) {split(s,a,":"); return a[1]*60+a[2]}
        function clock(m, d) {d=int(m/1440); m=m%1440; return sprintf("%02d:%02d%s",int(m/60),m%60,d ? " (+" d "d)" : "")}
        NR==FNR {if (FNR>1 && $1==today) {delay[$2]=$3; reason[$2]=$4} next}
        FNR==1 {printf "%-10s %-12s %-16s %-16s %s\n","ID","Status","Scheduled arrival","Expected arrival","Reason"; next}
        {a=mins($6); if(a<mins($5)) a+=1440
         if ($1 in delay) {
             status=(delay[$1]+0==0 ? "On time" : "Delayed")
             printf "%-10s %-12s %-16s %-16s %s\n",$1,status,clock(a),clock(a+delay[$1]),reason[$1]
         } else printf "%-10s %-12s %-16s %-16s %s\n",$1,"No update",clock(a),"Unknown","Not reported"
        }' "$DELAYS" "$SERVICES"
}

view_history() {
    local id
    read -r -p "Service ID (blank for all history): " id || return 1
    awk -F, -v id="$id" 'BEGIN {printf "%-12s %-10s %-8s %-22s %-22s %s\n","Date","ID","Minutes","Origin","Destination","Reason"}
        NR>1 && (id=="" || $2==id) {printf "%-12s %-10s %-8s %-22s %-22s %s\n",$1,$2,$3,$7,$8,$4; n++}
        END {if(!n) print "No delay records found."}' "$DELAYS"
}
