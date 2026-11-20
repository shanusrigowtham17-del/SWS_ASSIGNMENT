#!/usr/bin/env bash
# Summarize the latest saved observation per service per date.
write_report() {
    echo "PUBLIC TRANSPORT DELAY REPORT"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    awk -F, 'NR>1 {n++} END {printf "Current scheduled services: %d\n",n}' "$SERVICES"
    awk -F, '
        NR>1 {n++; total+=$3; if($3>0) late++; else ontime++
              if($3>max) {max=$3; worst=$2 " on " $1}}
        END {
            printf "Observations (all dates): %d\n",n
            printf "On-time observations: %d\nDelayed observations: %d\n",ontime,late
            if(n) {
                printf "Average delay across all observations: %.2f minutes\n",total/n
                printf "On-time rate among reported observations: %.2f%%\n",100*ontime/n
                printf "Maximum delay: %d minutes%s\n",max,(max>0 ? " (" worst ")" : "")
            } else print "No observations yet. Record a delay to build a report."
        }' "$DELAYS"
}

generate_report() {
    local report_dir report
    report_dir="$DATA_DIR/reports"
    mkdir -p "$report_dir" || return 1
    report=$(mktemp "$report_dir/report_$(date +%Y%m%d_%H%M%S)_XXXXXX") || return 1
    if write_report > "$report"; then
        cat "$report"
        echo "Report saved: $report"
    else
        rm -f "$report"; return 1
    fi
}
