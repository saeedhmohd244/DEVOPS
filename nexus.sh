#!/bin/bash 

# Author: Chris Parbey

logfile="/var/log/nexus-install.log"
current_datetime=$(date +"%Y-%m-%d %H:%M:%S")

# Function to log to both file and terminal
log () {
    echo "$1" | sudo tee -a "$logfile"
}

# Function to log and exit on error
log_and_exit () {
    echo "$1" | sudo tee -a "$logfile"
    exit 1
}

# Changing the Hostname of The EC2
log "Setting the hostname to nexus..."
sudo hostnamectl set-hostname nexus || log_and_exit "Unable to set the hostname for the Nexus server."

# Update and upgrade packages
log "Updating and upgrading packages..."
sudo apt update -y || log_and_exit "Unable to update packages."
log "Upgrading packages..."
sudo apt upgrade -y || log_and_exit "Failed to upgrade packages."

# Create user 'nexus' with sudo access
log "Creating user 'nexus' and granting sudo access..."
sudo adduser nexus
sudo echo "nexus ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/nexus > /dev/null
log "User nexus created successfully."

# Run commands as user 'nexus'
su -nexus
logfile="/var/log/nexus-install.log"
current_datetime=$(date +"%Y-%m-%d %H:%M:%S")

# Function to log to both file and terminal
log () {
    echo "$1" | sudo tee -a "$logfile"
}

# Function to log and exit on error
log_and_exit () {
    echo "$1" | sudo tee -a "$logfile"
    exit 1
}

# Install Java
(
cd /opt || log_and_exit "Unable to change to the opt directory."
log "Installing Java..."
sudo apt install openjdk-8-jdk -y || log_and_exit "Failed to install Java."
log "Java installation complete."

# Remove downloaded archive
log "Downloading Nexus..."
sudo wget https://download.sonatype.com/nexus/3/nexus-3.70.1-02-unix.tar.gz > /dev/null || log_and_exit "Failed to download Nexus."
log "Extracting Nexus..."
sudo tar -xzvf nexus-3.70.1-02-unix.tar.gz > /dev/null || log_and_exit "Failed to extract Nexus."

# Remove downloaded archive
log "Removing downloaded archive..."
sudo rm -rf nexus-3.70.1-02-unix.tar.gz || log_and_exit "Failed to remove downloaded archive."
log "Renaming extracted directory..."
sudo mv nexus-3.70.1-02 nexus || log_and_exit "Failed to rename extracted directory."
)
#nexus-3.70.1-02
# Change the ownership of Nexus and Sonatype-work directories
log "Changing ownership of Nexus directory..."
sudo chown -R nexus:nexus /opt/nexus || log_and_exit "Unable to change the ownership of the nexus directory."
log "Changing ownership of Sonatype-work directory..."
sudo chown -R nexus:nexus /opt/sonatype-work || log_and_exit "Unable to change the ownership of the Sonatype-work directory."

# Configure Nexus run-as user
log "Configuring Nexus run-as user..."
echo 'run_as_user="nexus"' | sudo tee /opt/nexus/bin/nexus.rc > /dev/null || log_and_exit "Failed to configure Nexus run-as user."

# Create systemd service for Nexus
log "Creating systemd service for Nexus..."
sudo tee /etc/systemd/system/nexus.service > /dev/null << EOF
[Unit]
Description=Nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

# Reload the systemd daemon
log "Reloading the systemd daemon..."
sudo systemctl daemon-reload || log_and_exit "Failed to reload the daemon."

# Start and enable Nexus
log "Starting and enabling Nexus service..."
sudo systemctl enable --now nexus.service || log_and_exit "Failed to enable nexus service."

log  "Nexus installation completed successfully at ${current_datetime}."
nexus
