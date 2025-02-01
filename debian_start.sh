# Kali Linux Start Script
#! /usr/bin/bash
echo "Starting the script with user: $USER and sudo user: $SUDO_USER"

# Update the system
echo "Updating the system..."
sudo apt update -y && sudo apt upgrade -y

# Install development essentials
sudo apt install git gh build-essential nodejs npm docker.io docker-compose code -y

# Set git config
git config --global user.name "Jack Hansen"
git config --global user.email "jackvwh@hotmail.com"
git config --global push.autoSetupRemote true
git config --global gpg.format ssh 
git config --global user.signingkey ~/.ssh/id_ed25519
git config --global commit.gpgsign true 

# Install Terraform
if ! command -v terraform &> /dev/null
then
    wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform
fi

# Install rustup and rust
if ! command -v rustup &> /dev/null
then
    echo "Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    rustup toolchain install nightly
    rustup default nightly
fi

# Install pnpm
echo "Installing pnpm..."
npm install -g pnpm

# Install JetBrains Toolbox
if ! command -v jetbrains-toolbox &> /dev/null
then
    echo "Installing JetBrains Toolbox..."
    sudo mkdir -p /opt/jetbrains
    wget -O jetbrains-toolbox.tar.gz "https://data.services.jetbrains.com/products/download?platform=linux&code=TBA"
    sudo tar -xzf jetbrains-toolbox.tar.gz -C /opt/jetbrains
    rm jetbrains-toolbox.tar.gz
    sudo ln -s /opt/jetbrains/jetbrains-toolbox-*/jetbrains-toolbox /usr/bin/jetbrains
fi

# Configure Docker
if command -v docker &> /dev/null
then
    # Remove any conflicting packages
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Linux post install docker
    sudo groupadd docker
    echo "Attempting to add user to docker group..."
    sudo usermod -aG docker $SUDO_USER
    sudo systemctl enable docker
    sudo systemctl enable containerd.service
    docker run hello-world
    if ! command -v docker &> /dev/null
        then
            echo "Docker installation failed. Please check your system for any conflicting packages and try again."
            exit 1
    fi
fi

# Install Google Chrome
if ! command -v google-chrome &> /dev/null
then
    echo "Installing Google Chrome..."
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
    sudo apt update
    sudo apt install google-chrome-stable
fi

# Set hostname
sudo hostnamectl set-hostname "mole"

echo "Installation complete. A reboot is required for Docker group changes to take effect."
read -p "Would you like to reboot now? (y/N): " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
then
    echo "Rebooting the system..."
    sudo reboot
else
    echo "Please remember to reboot your system later to apply all changes."
fi
