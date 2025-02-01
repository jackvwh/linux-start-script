# Kali Linux Start Script
#! /usr/bin/bash
echo "Starting the script with user: $USER and sudo user: $SUDO_USER"

# Update the system
echo "Updating the system..."
sudo apt update && sudo apt upgrade -y

# Install development essentials
sudo apt install git gh build-essential nodejs npm maven default-jdk openjdk-17-jdk mysql-workbench docker.io docker-compose code -y

# Set git config
git config --global user.name "Jack Hansen"
git config --global user.email "jackvwh@hotmail.com"
git config --global push.autoSetupRemote true
git config --global gpg.format ssh 
git config --global user.signingkey ~/.ssh/id_ed25519
git config --global commit.gpgsign true 

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
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo groupadd docker 2>/dev/null || true
    sudo usermod -aG docker $SUDO_USER
fi

# Install mattermost desktop
if ! command -v mattermost-desktop &> /dev/null
then
    echo "Installing Mattermost Desktop..."
    curl -fsS -o- https://deb.packages.mattermost.com/setup-repo.sh | sudo bash
    sudo apt install mattermost-desktop
    sudo apt upgrade mattermost-desktop
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
