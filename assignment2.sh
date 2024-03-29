#!/bin/bash
# Function to configure the network
netplan_change() {
    echo "Configuring the network..."
    cat <<EOF | sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses: [192.168.16.22/24]
      routes:
        - to: 0.0.0.0/0
          via: 192.168.16.1
      nameservers:
        addresses: [192.168.16.1]
        search: [home.arpa, localdomain]
EOF

    sudo netplan apply
}

# Call the function to configure the network
netplan_change

# Function to update the /etc/hosts file
hosts_file() {
    print_message "Updating /etc/hosts File"
    local new_entry="192.168.16.21    server1"

    # Remove old entry if present
sudo grep -v '^192\.168\.16\.21[[:space:]]\+server1$' /etc/hosts | sudo tee /etc/hosts >/dev/null

    # Add new entry
    echo "$new_entry" | sudo tee -a /etc/hosts >/dev/null
}

# Update /etc/hosts file
hosts_file

# Function to check and install required software
install_software() {
    print_message "Checking and Installing Required Software"

    # Check and install Apache2 if not installed
    if ! dpkg -l | grep -q 'apache2'; then
        sudo apt update
        sudo apt install -y apache2
        print_message "Apache2 installed."
    else
        print_message "Apache2 is already installed."
    fi

    # Check and install Squid if not installed
    if ! dpkg -l | grep -q 'squid'; then
        sudo apt update
        sudo apt install -y squid
        print_message "Squid installed."
    else
        print_message "Squid is already installed."
    fi
}

# Call the function to check and install required software
install_software

# Function to enable UFW and configure firewall rules
configure_firewall() {
    local mgmt_network_ip="<your_mgmt_network_ip>"  # Specify the management network IP here

    print_message "Configuring Firewall with UFW"

    # Enable UFW
    sudo ufw --force enable

    # Allow SSH on port 22 only on the management network
    sudo ufw allow from "$mgmt_network_ip" to any port 22

    # Allow HTTP on both interfaces
    sudo ufw allow http

    # Allow web proxy on both interfaces (assuming default Squid proxy port 3128)
    sudo ufw allow 3128

    # Reload UFW to apply changes
    sudo ufw reload
}

# Call the function to configure firewall rules using UFW
configure_firewall

create_users() {
    print_message "Creating User Accounts"

    # List of users to create
    local users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

    # Create users with home directory and bash shell
    for user in "${users[@]}"; do
        if ! id "$user" &>/dev/null; then
            sudo useradd -m -s /bin/bash "$user"
            echo "User '$user' created."

            # Generate RSA and Ed25519 keys for the user
            sudo -u "$user" ssh-keygen -t rsa -N "" -f "/home/$user/.ssh/id_rsa"
            sudo -u "$user" ssh-keygen -t ed25519 -N "" -f "/home/$user/.ssh/id_ed25519"

            # Append RSA and Ed25519 public keys to authorized_keys file
            cat "/home/$user/.ssh/id_rsa.pub" | sudo -u "$user" tee -a "/home/$user/.ssh/authorized_keys" >/dev/null
            cat "/home/$user/.ssh/id_ed25519.pub" | sudo -u "$user" tee -a "/home/$user/.ssh/authorized_keys" >/dev/null

            echo "SSH keys generated and added for user '$user'."
        else
            echo "User '$user' already exists."
        fi
    done
}

# Function to grant sudo access to specified user
grant_sudo_access() {
    local sudo_user="dennis"

    print_message "Granting Sudo Access to $sudo_user"
    sudo usermod -aG sudo "$sudo_user"
    echo "Sudo access granted to user '$sudo_user'."
}

# Call the function to create user accounts
create_users

# Call the function to grant sudo access
grant_sudo_access
