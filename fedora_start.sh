#!/usr/bin/bash

echo "Starting the script with user: $USER and sudo user: $SUDO_USER"

set -ex  # Exit on error and show each command
trap 'echo "An error occurred. Exiting..."; exit 1' ERR

# Enable NTP
echo "Enabling NTP..."
timedatectl set-ntp true

echo "Updating the system..."
sudo dnf upgrade --refresh -y

# Install common CLI tools
sudo dnf5 install -y git gh nodejs npm maven golang

# Install development tools group
sudo dnf5 install -y gcc gcc-c++ make automake autoconf kernel-devel

# Install Terraform
if ! command -v terraform &> /dev/null; then
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
    sudo dnf -y install terraform
fi

# Install pgAdmin4
if ! command -v pgadmin4 &> /dev/null; then
    echo "Installing pgAdmin4..."
    sudo rpm -i https://ftp.postgresql.org/pub/pgadmin/pgadmin4/yum/pgadmin4-fedora-repo-2-1.noarch.rpm || true
    sudo dnf5 install -y pgadmin4-desktop
fi

# Install pnpm
echo "Installing pnpm..."
npm install -g pnpm

# Install Java latest
echo "Installing Java latest OpenJDK..."
sudo dnf5 install -y java-latest-openjdk-devel.x86_64

# Install Golang
echo "Installing Golang..."
sudo dnf install -y golang

# Create GOPATH directory
echo "Setting up GOPATH..."
mkdir -p "$HOME/go"

# Export GOPATH to .bashrc if not already present
if ! grep -q "export GOPATH=" "$HOME/.bashrc"; then
    echo 'export GOPATH=$HOME/go' >> "$HOME/.bashrc"
fi

# Source .bashrc so changes take effect in this session
source "$HOME/.bashrc"

# Fedora 43 specific defaults
echo "Configuring Fedora 43 Go defaults..."
# Keep Fedora's default: GOTOOLCHAIN=local
go env -w GOTOOLCHAIN=local

# Optional: uncomment these if you prefer direct proxy and no sumdb
# go env -w GOPROXY=direct
# go env -w GOSUMDB=off

# Verify installation
echo "Go version:"
go version
echo "GOPATH:"
go env GOPATH

# Install JetBrains Toolbox
if ! command -v jetbrains-toolbox &> /dev/null; then
    echo "Installing JetBrains Toolbox..."
    sudo mkdir -p /opt/jetbrains
    wget -O jetbrains-toolbox.tar.gz "https://data.services.jetbrains.com/products/download?platform=linux&code=TBA"
    sudo tar -xzf jetbrains-toolbox.tar.gz -C /opt/jetbrains
    rm jetbrains-toolbox.tar.gz
    TOOLBOX_BIN=$(find /opt/jetbrains -name jetbrains-toolbox | head -n 1)
    sudo ln -sf "$TOOLBOX_BIN" /usr/bin/jetbrains
    echo "JetBrains Toolbox installed successfully."
fi

# Install VS Code
if ! command -v code &> /dev/null; then
    echo "Installing VS Code..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf5 check-update || true
    sudo dnf5 install -y code
fi

# Install Docker Engine
if ! command -v docker &> /dev/null; then
    echo "Installing Docker Engine..."
    sudo dnf5 remove -y docker docker-client docker-client-latest docker-common docker-latest \
        docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine || true

    sudo dnf5 install -y dnf5-plugins
    sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf5 install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo systemctl enable --now docker
    sudo docker run hello-world || echo "Docker hello-world test failed (non-fatal)"

    echo "Adding user to docker group..."
    sudo groupadd docker || true
    sudo usermod -aG docker "$SUDO_USER"
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
fi

# Install Brave browser
if ! command -v brave &> /dev/null; then
    echo "Installing Brave Browser..."
    curl -fsS https://dl.brave.com/install.sh | sh
fi

# Install Chrome browser
if ! command -v google-chrome &> /dev/null; then
    echo "Installing Chrome Browser..."
    sudo dnf5 install -y google-chrome-stable || true
fi

# Install Slack via Flatpak
if ! command -v slack &> /dev/null; then
    echo "Installing Slack..."
    flatpak install flathub com.slack.Slack -y || true
fi

# Install Obsidian
if ! command -v obsidian &> /dev/null; then
    echo "Installing Obsidian..."
    sudo snap install obsidian --classic
fi

# Setup SSH folder and keys
mkdir -p ~/.ssh
touch ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 700 ~/.ssh

# Set hostname
sudo hostnamectl set-hostname "mole"

# Set Git config
echo "Setting git config variables"
git config --global user.name "Jack Hansen"
git config --global user.email "jackvwh@hotmail.com"
git config --global push.autoSetupRemote true
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519
git config --global commit.gpgsign true

# Install Session Manager Plugin
sudo dnf5 install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm

# Set custom aliases (safe fallback for user detection)
echo "Setting custom aliases..."
target_bashrc="/home/${SUDO_USER:-$USER}/.bashrc"
echo "alias update='sudo dnf5 upgrade --refresh -y'" >> "$target_bashrc"
echo "alias install='sudo dnf5 install -y'" >> "$target_bashrc"

echo "Installation complete. A reboot is required for Docker group changes to take effect."
read -p "Would you like to reboot now? (y/N): " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    echo "Rebooting the system..."
    sudo reboot
else
    echo "Please remember to reboot your system later to apply all changes."
fi
