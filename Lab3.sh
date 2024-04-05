#!/bin/bash

usage() {
    echo "Usage: $0 [-v]"
    echo "Options:"
    echo "  -v, --verbose    Run in verbose mode"
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true; shift ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

run_command() {
    local cmd="$1"
    local desc="$2"
    if $cmd; then
        echo "$desc completed successfully."
    else
        echo "Error: $desc failed."
        exit 1
    fi
}

run_command "scp configure-host.sh remoteadmin@server1-mgmt:/root" "Transfer configure-host.sh to server1-mgmt"
run_command "ssh remoteadmin@server1-mgmt -- /root/configure-host.sh -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4 $([[ "$VERBOSE" == true ]] && echo '-verbose')" "Run configure-host.sh on server1-mgmt"
run_command "scp configure-host.sh remoteadmin@server2-mgmt:/root" "Transfer configure-host.sh to server2-mgmt"
run_command "ssh remoteadmin@server2-mgmt -- /root/configure-host.sh -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3 $([[ "$VERBOSE" == true ]] && echo '-verbose')" "Run configure-host.sh on server2-mgmt"
run_command "./configure-host.sh -hostentry loghost 192.168.16.3 $([[ "$VERBOSE" == true ]] && echo '-verbose')" "Run configure-host.sh locally for loghost entry"
run_command "./configure-host.sh -hostentry webhost 192.168.16.4 $([[ "$VERBOSE" == true ]] && echo '-verbose')" "Run configure-host.sh locally for webhost entry"

echo "All configurations applied successfully."
