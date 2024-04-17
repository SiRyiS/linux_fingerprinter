#!/bin/bash

print_info() {
    echo "[$1]: $2"
}

# users and groups info
print_info "INFO" "Current User:

$(whoami)"

echo "---------------------------------------------------------------------------------------------------------------------------"

print_info "INFO" "Other Potential Users:

$(ls -lR / 2>/dev/null | awk '$3 ~ /^[a-zA-Z]/ {print $3}' | sort -u
)" 

echo "---------------------------------------------------------------------------------------------------------------------------"

print_info "INFO" "Potential Groups:

$(stat /*/*/* 2>/dev/null | grep 'Gid:' | awk '{print $5,$6}' | tr ',' '\n' | sort -u)"

echo "---------------------------------------------------------------------------------------------------------------------------"

# basic system info
print_info "INFO" "Kernel & Distribution:

$(printf "%s " "$(uname -a | awk '{print $3}')" "$(lsb_release -ds | cut -d: -f2-)" "$(lsb_release -sr)")"

echo "---------------------------------------------------------------------------------------------------------------------------"

# network info
print_info "INFO" "Network Interfaces:

$(ip a | grep '^[0-9]' | cut -d ' ' -f2 | tr '\n' ' ' | column -t)"

echo "---------------------------------------------------------------------------------------------------------------------------"

print_info "INFO" "Route Info:

$(ip route show)"

echo "---------------------------------------------------------------------------------------------------------------------------"

# look for open ports
print_info "INFO" "Listening Ports:

$(netstat -tuln 2>/dev/null | awk '/^tcp/ {print $4}' | cut -d ':' -f2 | sort -u | tr '\n' ' ')"

echo "---------------------------------------------------------------------------------------------------------------------------"

# running services
print_info "INFO" "Running Processes:

$(ps aux)"

echo "---------------------------------------------------------------------------------------------------------------------------"

# check for potentially misconfigured services
check_services() {
    echo "=== Services to Investigate ==="
    echo
    while IFS= read -r line; do
        exec_path=$(echo "$line" | awk '{print $11}')
        if [[ -n "$exec_path" && "$exec_path" == *"/"* ]]; then
            echo "$exec_path"
        fi
    # you can exclude root services by switching the below
    # done < <(ps aux | awk 'NR > 1 && $1 != "root" {print}')
    done < <(ps aux | awk 'NR > 1 {print}' | column -t)
}

check_services 2>/dev/null

echo "---------------------------------------------------------------------------------------------------------------------------"

# check for excutable permission files
check_files() {
    echo "=== Potential Files to Investigate ==="
    echo
    find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -l {} + 2>/dev/null
}
check_files

echo "---------------------------------------------------------------------------------------------------------------------------"

# filesystem info
print_info "INFO" "Disk Usage:

$(df -h)"

echo "---------------------------------------------------------------------------------------------------------------------------"

print_info "INFO" "Mount Points:

$(awk '{print $5}' /proc/self/mountinfo | grep -vE '^$' | column -t)"

echo "---------------------------------------------------------------------------------------------------------------------------"

# files/executables with SUID bit
print_info "INFO" "SUID bit on"
find /*/*/* -type f \( -perm -4000 -o -perm -2000 \) -exec ls -l {} + 2>/dev/null

echo "---------------------------------------------------------------------------------------------------------------------------"

clear_logs() {

    echo "=== Clear Logs ==="
    echo

    error=0

    # clear terminal history
    if history -c; then
        echo "Command History Cleared"
        echo "==============================="
    else
        echo "Error: Failed to clear command history"
        error=1
        echo "==============================="
    fi

    # clear syslog
    if cat /dev/null > /var/log/syslog; then
        echo "Syslog Cleared"
        echo "==============================="
    else
        echo "Error: Failed to clear syslog"
        error=1
        echo "==============================="
    fi

    # clear auth.log
    if cat /dev/null > /var/log/auth.log; then
        echo "Auth.log Cleared"
        echo "==============================="
    else
        echo "Error: Failed to clear auth.log"
        error=1
        echo "==============================="
    fi
}

clear_logs
