#! /usr/bin/bash
echo "Starting the script with user: $USER and sudo user: $SUDO_USER"

echo "Updating the system..."
sudo dnf upgrade --refresh -y

#install mysql workbench
if ! command -v mysql-workbench &> /dev/null
then
    echo "Installing MySQL Workbench..."
    wget https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community-8.0.36-1.fc38.x86_64.rpm
    sudo dnf install mysql-workbench-community-8.0.36-1.fc38.x86_64.rpm -y
fi

#install pgadmin4
if ! command -v pgadmin4 &> /dev/null
then
    echo "Installing pgAdmin4..."
    sudo rpm -i https://ftp.postgresql.org/pub/pgadmin/pgadmin4/yum/pgadmin4-redhat-repo-2-1.noarch.rpm
    sudo dnf install pgadmin4-desktop -y 
fi

#install steam
if ! command -v steam &> /dev/null
then
    echo "Installing Steam..."
    sudo dnf install steam -y
fi

#install newest nvidia drivers
if ! command -v nvidia-smi &> /dev/null
then
    echo "Installing the latest NVIDIA drivers..."
    sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/fedora39/x86_64/cuda-fedora39.repo
    sudo dnf install kernel-headers kernel-devel tar bzip2 make automake gcc gcc-c++ pciutils elfutils-libelf-devel libglvnd-opengl libglvnd-glx libglvnd-devel acpid pkgconfig dkms -y
    sudo dnf module install nvidia-driver:latest-dkms -y
fi

# install nodejs and  npm
echo "Installing Node.js and npm..."
sudo dnf install nodejs npm -y

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
    sudo docker run hello-world
# linux post install docker
    sudo groupadd docker
    echo "Attempting to add user to docker group..."
    sudo usermod -aG docker $SUDO_USER
    sudo systemctl enable docker
fi


echo "Installing Java 17 and latest OpenJDK..."
sudo dnf install java-17-openjdk-devel.x86_64 -y
sudo dnf install java-latest-openjdk-devel.x86_64 -y


#install Maven
if ! command -v mvn &> /dev/null
then
    echo "Installing Maven..."
    sudo dnf install maven -y
fi

#install Mattermost Desktop from flathub
if ! command -v mattermost-desktop &> /dev/null
then
    echo "Installing Mattermost Desktop..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install flathub com.mattermost.Desktop -y
    flatpak run com.mattermost.Desktop
fi

# install Chrome browser from Flathub
if ! command -v google-chrome &> /dev/null
then
    echo "Installing Google Chrome..."
    flatpak install flathub com.google.Chrome -y
    flatpak run com.google.Chrome
fi

# install Multimedia Codecs
sudo dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel -y
sudo dnf install lame\* --exclude=lame-devel -y
sudo dnf group upgrade --with-optional Multimedia -y

# set hostname
sudo hostnamectl set-hostname "mole"

# Choose Java version
echo "Selecting the default Java version..."
sudo alternatives --config java

echo "Installation complete. A reboot is required for Docker group changes to take effect."
read -p "Would you like to reboot now? (y/N): " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
then
    echo "Rebooting the system..."
    sudo reboot
else
    echo "Please remember to reboot your system later to apply all changes."
fi
