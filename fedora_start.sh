#! /usr/bin/bash
echo "Starting the script with user: $USER and sudo user: $SUDO_USER"

echo "Updating the system..."
sudo dnf update -y

# install nodejs and  npm
echo "Installing Node.js and npm..."
sudo dnf install nodejs npm -y


read -p "Would you like to install Jetbrains IntelliJ IDEA Ultimate? (y/N): " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
then
    echo "Installing Jetbrains IntelliJ IDEA Ultimate..."
    # Download the tar.gz file to the current directory
    wget https://download.jetbrains.com/idea/ideaIU-2021.2.2.tar.gz
    # Extract it to /opt (or another directory of your choice)
    sudo tar -xzf ideaIU-2021.2.2.tar.gz -C /opt
    # Optionally, add the installation bin directory to the PATH or create a launcher

    # Create a desktop file
    echo "[Desktop Entry]
    Version=1.0
    Type=Application
    Name=IntelliJ IDEA Ultimate
    Icon=/opt/idea-IU-212.5284.40/bin/idea.png
    Exec="/opt/idea-IU-212.5284.40/bin/idea.sh" %f
    Comment=Capable and Ergonomic IDE for JVM
    Categories=Development;IDE;
    Terminal=false
    StartupWMClass=jetbrains-idea" > ~/.local/share/applications/idea.desktop
    

    # Make the desktop file executable
    sudo chmod +x ~/.local/share/applications/idea.desktop
    # Remove the downloaded tar.gz file
    rm ideaIU-2021.2.2.tar.gz
fi



#install vscode
if ! command -v code &> /dev/null
then
    echo "Installing VS Code..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf check-update
    sudo dnf -y install code # or code-insiders
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
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl start docker
# linux post install docker
    echo "Attempting to add user to docker group..."
    sudo usermod -aG docker $SUDO_USER
    sudo systemctl enable docker
fi

echo "Installation complete. A reboot is required for Docker group changes to take effect."
read -p "Would you like to reboot now? (y/N): " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
then
    echo "Rebooting the system..."
    sudo reboot
else
    echo "Please remember to reboot your system later to apply all changes."
fi
