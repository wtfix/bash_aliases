#!/bin/bash

# System services
alias systemctl-list-units='systemctl list-units'
alias systemctl-list-unit-files='systemctl list-unit-files'

# Check for systemd failed services
alias systemd-check-failed='systemctl --failed'

# List all services
alias systemd-list-all='systemctl list-unit-files'

alias systemctl-list-timers='systemctl list-timers'


service-rules-install() {
    local service_name="$1"

    # Validate input
    if [ -z "$service_name" ]; then
        echo "Error: No service name provided."
        return 1
    fi

    local username=$(whoami)  # Get the current user's username
    local rule_file="/etc/polkit-1/rules.d/50-${service_name}.rules"

    # Check if systemctl exists and get its path
    local systemctl_path=$(which systemctl)

    if [ -z "$systemctl_path" ]; then
        echo "Error: systemctl not found."
        return 1
    fi

    # Create the Polkit rule file if it does not exist
    if [ ! -f "$rule_file" ]; then
        echo "Creating Polkit rule file for $service_name..."
        sudo bash -c "cat > $rule_file <<EOF
polkit.addRule(function(action, subject) {
    if (action.id == 'org.freedesktop.systemd1.manage-units' && subject.isInGroup('$username')) {
        return polkit.Result.YES;
    }
});
EOF"
        echo "Polkit rule file created successfully."
    else
        echo "Polkit rule file already exists."
    fi

    # Check if the user is in the necessary group (derived from service name)
    local group_name="${service_name%%.*}"  # Use part before the dot as group name
    if ! groups "$username" | grep -q "\b$group_name\b"; then
        echo "Adding user $username to the $group_name group..."
        sudo usermod -aG "$group_name" "$username"
        echo "User $username added to $group_name group."
    else
        echo "User $username is already in the $group_name group."
    fi

    # Add sudoers entries for starting and stopping the service without a password
    local sudoers_file="/etc/sudoers.d/${service_name}-service"

    if ! sudo grep -q "$username ALL=(ALL) NOPASSWD: $systemctl_path start $service_name" "$sudoers_file" 2>/dev/null; then
        echo "Adding sudoers entries for $service_name..."
        {
            echo "$username ALL=(ALL) NOPASSWD: $systemctl_path start $service_name"
            echo "$username ALL=(ALL) NOPASSWD: $systemctl_path stop $service_name"
        } | sudo tee -a "$sudoers_file" > /dev/null
        echo "Sudoers entries added successfully."
    else
        echo "Sudoers entries already exist."
    fi

    echo "All necessary rules and groups have been set up for $username to manage $service_name."
}
