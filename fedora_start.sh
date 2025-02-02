#! /usr/bin/bash
echo "Starting the script with user: $USER and sudo user: $SUDO_USER"

echo "Updating the system..."
sudo dnf upgrade --refresh -y

#install git
if ! command -v git &> /dev/null
then
    echo "Installing git..."
    sudo dnf install git -y
fi

#install git cli
if ! command -v gh &> /dev/null
then
    echo "Installing gh cli..."
    sudo dnf install gh -y
fi

# Set git config
git config --global user.name "Jack Hansen"
git config --global user.email "jackvwh@hotmail.com"
git config --global push.autoSetupRemote true
git config --global gpg.format ssh 
git config --global user.signingkey ~/.ssh/id_ed25519
git config --global commit.gpgsign true 


#install development tools
sudo dnf groupinstall "Development Tools" -y

# Install Terraform
if ! command -v terraform &> /dev/null
then
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
    sudo dnf -y install terraform
fi

#install pgadmin4
if ! command -v pgadmin4 &> /dev/null
then
    echo "Installing pgAdmin4..."
    sudo rpm -i https://ftp.postgresql.org/pub/pgadmin/pgadmin4/yum/pgadmin4-fedora-repo-2-1.noarch.rpm
    sudo dnf install pgadmin4-desktop -y 
fi

# install nodejs and npm
echo "Installing Node.js and npm..."
sudo dnf install nodejs npm -y

# install pnpm
echo "Installing pnpm..."
npm install -g pnpm

# install JetBrains Toolbox
if ! command -v jetbrains-toolbox &> /dev/null
then
    echo "Installing JetBrains Toolbox..."
    sudo mkdir /opt/jetbrains
    wget -O jetbrains-toolbox.tar.gz "https://data.services.jetbrains.com/products/download?platform=linux&code=TBA"
    sudo tar -xzf jetbrains-toolbox.tar.gz -C /opt/jetbrains
    rm jetbrains-toolbox.tar.gz
    sudo ln -s /opt/jetbrains/jetbrains-toolbox-*/jetbrains-toolbox /usr/bin/jetbrains
    echo "JetBrains Toolbox installed successfully."
fi

#install vscode
if ! command -v code &> /dev/null
then
    echo "Installing VS Code..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf check-update
    sudo dnf -y install code 
fi

#install docker engine
if ! command -v docker &> /dev/null
then
    echo "Installing Docker Engine..."
    sudo dnf -y remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine

    sudo dnf -y install dnf-plugins-core
    
    sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

    sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo docker run hello-world

# linux post install docker
    sudo groupadd docker
    echo "Attempting to add user to docker group..."
    sudo usermod -aG docker $SUDO_USER
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
fi

# Install Brave browser
if ! command -v brave &> /dev/null
then
    echo "Installing Brave Browser..."
    curl -fsS https://dl.brave.com/install.sh | sh
fi

# install Multimedia Codecs
sudo dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel -y
sudo dnf install lame\* --exclude=lame-devel -y
sudo dnf group upgrade --with-optional Multimedia -y

# Install Slack flathub 
if ! command -v slack &> /dev/null
then
    echo "Installing Slack..."
    flatpak install flathub com.slack.Slack -y
fi

# Install Golang
if ! command -v go &> /dev/null
then
    echo "Installing Golang..."
    sudo dnf install golang -y
    if ! command -v go &> /dev/null
        then
            echo "Golang installation failed. Please install golang manually."
            exit 1
    fi
fi

# set hostname
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