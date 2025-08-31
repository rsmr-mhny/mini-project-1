#!/bin/bash

sched=()

center() {
    local s="$1"
    local w="$2"
    local len=${#s}
    local spaces=$(( w - len ))
    local left=$(( spaces / 2 ))
    local right=$(( spaces - left ))

    pad_left=""
    for ((i=0; i<left; i++)); do pad_left="$pad_left "; done
    pad_right=""
    for ((i=0; i<right; i++)); do pad_right="$pad_right "; done

    echo -n "$pad_left$s$pad_right"
}

print_schedule() {
    local width_team=8
    local width_shift=10
    local width_emp=12  # minimum

    # Find max employee list length
    max_emp=0
    for key in $(echo -e "${sched[@]}" | cut -d',' -f1,2 | sort -u); do
        # Collect all employees for this team+shift
        employees=$(echo -e "${sched[@]}" | grep "^$key," | cut -d',' -f3 | paste -sd ", ")
        length=${#employees}

        # Update max if this list is longer
        if [ $length -gt $max_emp ]; then
            max_emp=$length
        fi
    done

    # Adjust column width if needed
    if [ $max_emp -gt $width_emp ]; then
        width_emp=$((max_emp + 2))
    fi

    # Top border
    printf "╔%s╦%s╦%s╗\n" \
        "$(printf '═%.0s' $(seq 1 $width_team))" \
        "$(printf '═%.0s' $(seq 1 $width_shift))" \
        "$(printf '═%.0s' $(seq 1 $width_emp))"

    # Header row
    printf "║\033[1m%s\033[0m║\033[1m%s\033[0m║\033[1m%s\033[0m║\n" \
        "$(center "Team" $width_team)" \
        "$(center "Shift" $width_shift)" \
        "$(center "Employees" $width_emp)"

    # Divider
    printf "╠%s╬%s╬%s╣\n" \
        "$(printf '═%.0s' $(seq 1 $width_team))" \
        "$(printf '═%.0s' $(seq 1 $width_shift))" \
        "$(printf '═%.0s' $(seq 1 $width_emp))"

    # Rows
    for team in $(echo -e "${sched[@]}" | cut -d',' -f1 | sort -u); do
        for shift in morning mid night; do
            employees=$(echo -e "${sched[@]}" | grep "^$team,$shift," | cut -d',' -f3 | paste -sd ", " - | sed 's/,/, /g')
            if [ -n "$employees" ]; then
                printf "║%s║%s║%s║\n" \
                    "$(center "$team" $width_team)" \
                    "$(center "$shift" $width_shift)" \
                    "$(center "$employees" $width_emp)"
            fi
        done

        # Divider between teams, except after the last team
        if [ "$team" != "$(echo -e "${sched[@]}" | cut -d',' -f1 | sort -u | tail -1)" ]; then
            printf "╠%s╬%s╬%s╣\n" \
                "$(printf '═%.0s' $(seq 1 $width_team))" \
                "$(printf '═%.0s' $(seq 1 $width_shift))" \
                "$(printf '═%.0s' $(seq 1 $width_emp))"        
        fi
    done
    # Bottom border
    printf "╚%s╩%s╩%s╝\n" \
    "$(printf '═%.0s' $(seq 1 $width_team))" \
    "$(printf '═%.0s' $(seq 1 $width_shift))" \
    "$(printf '═%.0s' $(seq 1 $width_emp))"
}

while true; do
		# Accept user input
    read -p "Enter Employee name (or 'print' to display schedule, 'exit' to quit): " name
    if [[ "$name" == "exit" ]]; then
        break
    fi
    if [[ "$name" == "print" ]]; then
        print_schedule
        continue
    fi

    read -p "Enter Shift (morning/mid/night): " shift
    shift=$(echo "$shift" | tr '[:upper:]' '[:lower:]')
    # Display error for invalid shift
    if [[ ! "$shift" =~ ^(morning|mid|night)$ ]]; then
        echo -e "❌ Invalid shift. Must be: morning, mid, or night.\n"
        break
    fi

    read -p "Enter Team (a1/a2/a3/b1/b2/b3): " team
    team=$(echo "$team" | tr '[:upper:]' '[:lower:]')
    # Display error for invalid team
    if [[ ! "$team" =~ ^(a1|a2|a3|b1|b2|b3)$ ]]; then
        echo -e "❌ Invalid team. Must be one of: a1, a2, a3, b1, b2, b3.\n"
        break
    fi

    sched+="$team,$shift,$name\n"
    echo -e "✅ Assigned $name to team $team ($shift shift).\n"
done
