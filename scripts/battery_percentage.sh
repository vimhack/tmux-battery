#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/helpers.sh"

print_battery_percentage() {
    # percentage displayed in the 2nd field of the 2nd row
    if is_wsl; then
        local battery
        battery=$(find /sys/class/power_supply/*/capacity | tail -n1)
        cat "$battery"
    elif command_exists "pmset"; then
        pmset -g batt | grep -o "[0-9]\{1,3\}%"
    elif command_exists "acpi"; then
        acpi -b | grep -m 1 -Eo "[0-9]+%"
    elif command_exists "upower"; then
        # use DisplayDevice if available otherwise battery
        local battery=$(upower -e | grep -E 'battery|DisplayDevice' | tail -n1)
        if [ -z "$battery" ]; then
            return
        fi
        local percentage=$(upower -i $battery | awk '/percentage:/ {print $2}')
        if [ "$percentage" ]; then
            echo ${percentage%.*%}
            return
        fi
        local energy
        local energy_full
        energy=$(upower -i $battery | awk -v nrg="$energy" '/energy:/ {print nrg+$2}')
        energy_full=$(upower -i $battery | awk -v nrgfull="$energy_full" '/energy-full:/ {print nrgfull+$2}')
        if [ -n "$energy" ] && [ -n "$energy_full" ]; then
            echo $energy $energy_full | awk '{printf("%d%%", ($1/$2)*100)}'
        fi
    elif command_exists "termux-battery-status"; then
        termux-battery-status | jq -r '.percentage' | awk '{printf("%d%%", $1)}'
    elif command_exists "apm"; then
        apm -l
    fi
}

main() {
    local update_interval=$(get_tmux_option $battery_update_interval_option $battery_update_interval_default)
    local current_time=$(date "+%s")
    local previous_update=$(get_tmux_option "@percentage_previous_update_time")
    local delta=$((current_time - previous_update))

    if [[ -z "$previous_update" ]] || [[ $delta -ge $update_interval ]]; then
        local value=$(
            print_battery_percentage
        )

        if [ "$?" -eq 0 ]; then
            set_tmux_option "@percentage_previous_update_time" "$current_time"
            set_tmux_option "@percentage_previous_value" "$value"
        fi
    fi

    echo -n "$(get_tmux_option "@percentage_previous_value")"

}

main
