#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/helpers.sh"

# script global variables
icon_status_charged=''
icon_status_charging=''
icon_status_discharging=''
icon_status_attached=''
icon_status_unknown=''

# script default variables
icon_status_charged_default='🔌'
icon_status_charged_default_osx='🔌'
icon_status_charging_default='🔌'
icon_status_discharging_default='🔋'
icon_status_attached_default='⚠️'
icon_status_unknown_default='?'

# determine which charged_default variable to use
get_icon_status_charged_default() {
    if is_osx; then
        printf "$icon_status_charged_default_osx"
    else
        printf "$icon_status_charged_default"
    fi
}

# icons are set as script global variables
get_icon_status_settings() {
    icon_status_charged=$(get_tmux_option "@batt_icon_status_charged" "$(get_icon_status_charged_default)")
    icon_status_charging=$(get_tmux_option "@batt_icon_status_charging" "$icon_status_charging_default")
    icon_status_discharging=$(get_tmux_option "@batt_icon_status_discharging" "$icon_status_discharging_default")
    icon_status_attached=$(get_tmux_option "@batt_icon_status_attached" "$icon_status_attached_default")
    icon_status_unknown=$(get_tmux_option "@batt_icon_status_unknown" "$icon_status_unknown_default")
}

print_icon_status() {
    local status=$1
    if [[ $status =~ (charged) || $status =~ (full) ]]; then
        printf "$icon_status_charged"
    elif [[ $status =~ (^charging) ]]; then
        printf "$icon_status_charging"
    elif [[ $status =~ (^discharging) ]]; then
        printf "$icon_status_discharging"
    elif [[ $status =~ (attached) ]]; then
        printf "$icon_status_attached"
    else
        printf "$icon_status_unknown"
    fi
}

main() {
    local update_interval=$(get_tmux_option $battery_update_interval_option $battery_update_interval_default)
    local current_time=$(date "+%s")
    local previous_update=$(get_tmux_option "@iconstatus_previous_update_time")
    local delta=$((current_time - previous_update))

    if [[ -z "$previous_update" ]] || [[ $delta -ge $update_interval ]]; then
        local value=$(
            get_icon_status_settings
            local status=${1:-$(battery_status)}
            print_icon_status "$status"
        )

        if [ "$?" -eq 0 ]; then
            set_tmux_option "@iconstatus_previous_update_time" "$current_time"
            set_tmux_option "@iconstatus_previous_value" "$value"
        fi
    fi

    echo -n "$(get_tmux_option "@iconstatus_previous_value")"
}

main
