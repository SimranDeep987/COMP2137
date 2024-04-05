#!/bin/bash

# Function to log messages if VERBOSE is true
log_message() {
    if [ "$VERBOSE" = true ]; then
        echo "$1"
    fi
}

# Configure hostname
if [ -n "$NEW_HOSTNAME" ]; then
    CURRENT_HOSTNAME=$(hostname)
    if [ "$CURRENT_HOSTNAME" != "$NEW_HOSTNAME" ]; then
        echo "$NEW_HOSTNAME" > /etc/hostname
        sed -i "s/^.*$CURRENT_HOSTNAME/$(echo $NEW_HOSTNAME | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')/" /etc/hosts
        log_message "Hostname updated to $NEW_HOSTNAME"
        logger "Hostname updated to $NEW_HOSTNAME"
    fi
fi

# Configure IP address
if [ -n "$NEW_IP" ]; then
    CURRENT_IP=$(hostname -I | awk '{print $1}')
    if [ "$CURRENT_IP" != "$NEW_IP" ]; then
        sed -i "s/$CURRENT_IP/$NEW_IP/g" /etc/hosts
        sed -i "s/address .*/address $NEW_IP/g" /etc/netplan/*.yaml
        log_message "IP address updated to $NEW_IP"
        logger "IP address updated to $NEW_IP"
    fi
fi

update_host_entry() {
    local desired_hostname="$1"
    local desired_ip="$2"
    if ! grep -q "$desired_ip\s\+$desired_hostname" /etc/hosts; then
        echo "$desired_ip $desired_hostname" >> /etc/hosts
        log_message "Added $desired_hostname with IP $desired_ip to /etc/hosts"
    fi
}

trap 'exit 0' TERM HUP INT

if [ -n "$UPDATE_SYSTEM_INFO" ]; then
    update_system_info
fi

if [ -n "$UPDATE_NETWORK_INFO" ]; then
    update_network_info
fi

if [ -n "$NEW_HOST_ENTRIES" ]; then
    IFS=',' read -ra HOST_ENTRIES <<< "$NEW_HOST_ENTRIES"
    for entry in "${HOST_ENTRIES[@]}"; do
        IFS='=' read -ra host_info <<< "$entry"
        update_host_entry "${host_info[1]}" "${host_info[0]}"
    done
fi
