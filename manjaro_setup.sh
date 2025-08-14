#!/usr/bin/env bash
# Manjaro setup script (Arch-based), Java removed

echo "Starting the script with user: $USER and sudo user: $SUDO_USER"

set -euo pipefail
set -x
trap 'echo "An error occurred. Exiting..."; exit 1' ERR

REAL_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$REAL_USER" | cut -d: -f6)"
TARGET_BASHRC="$HOME_DIR/.bashrc"

# Require root
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (use: sudo $0)"; exit 1
fi

# Enable NTP
echo "Enabling NTP..."
timedatectl set-ntp true || true

# Helpers
has() { command -v "$1" >/dev/null 2>&1; }
pac_install() { sudo pacman -S --needed --noconfirm "$@"; }
pac_refresh() { sudo pacman -Syu --noconfirm; }

# Update
echo "Updating the system..."
pac_refresh

# Core dev stack (no Java)
pac_install base-devel git github-cli nodejs npm maven go \
  gcc make automake autoconf linux-headers

# Terraform
if ! has terraform; then
  pac_install terraform || true
fi

# Flatpak & Flathub
if ! has flatpak; then pac_install flatpak; fi
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

# pgAdmin4 (Flatpak)
if ! has pgadmin4 && ! flatpak info org.pgadmin.pgadmin4 >/dev/null 2>&1; then
  echo "Installing pgAdmin4 (Flatpak)..."
  sudo -u "$REAL_USER" flatpak install -y flathub org.pgadmin.pgadmin4 || true
fi

# pnpm (repo preferred, npm fallback)
if ! has pnpm; then
  pac_install pnpm || sudo -u "$REAL_USER" npm install -g pnpm || true
fi

# JetBrains Toolbox
if ! has jetbrains-toolbox && ! has jetbrains; then
  echo "Installing JetBrains Toolbox..."
  JB_DIR="/opt/jetbrains"
  mkdir -p "$JB_DIR"
  wget -O /tmp/jetbrains-toolbox.tar.gz "https://data.services.jetbrains.com/products/download?platform=linux&code=TBA"
  tar -xzf /tmp/jetbrains-toolbox.tar.gz -C "$JB_DIR"
  rm -f /tmp/jetbrains-toolbox.tar.gz
  TOOLBOX_BIN="$(find "$JB_DIR" -name jetbrains-toolbox -type f | head -n 1 || true)"
  if [[ -n "${TOOLBOX_BIN:-}" ]]; then
    ln -sf "$TOOLBOX_BIN" /usr/bin/jetbrains-toolbox
    ln -sf "$TOOLBOX_BIN" /usr/bin/jetbrains
  fi
fi

# VS Code (OSS build). For MS build, use AUR via pamac (commented).
if ! has code; then
  pac_install code || true
  # pamac build --no-confirm visual-studio-code-bin || true
fi

# Docker + compose + buildx
if ! has docker; then
  pac_install docker docker-buildx docker-compose
  systemctl enable --now docker
  getent group docker >/dev/null 2>&1 || groupadd docker
  usermod -aG docker "$REAL_USER" || true
  sudo -u "$REAL_USER" docker run --rm hello-world || echo "Docker hello-world test failed (non-fatal)"
fi

# Brave
if ! has brave && ! has brave-browser; then
  pac_install brave-browser || true
  # pamac build --no-confirm brave-bin || true
fi

# Google Chrome (AUR via pamac if available)
if ! has google-chrome && has pamac; then
  pamac build --no-confirm google-chrome || true
fi

# Slack (Flatpak)
if ! has slack && ! flatpak info com.slack.Slack >/dev/null 2>&1; then
  echo "Installing Slack (Flatpak)..."
  sudo -u "$REAL_USER" flatpak install -y flathub com.slack.Slack || true
fi

# Obsidian (Flatpak)
if ! has obsidian && ! flatpak info md.obsidian.Obsidian >/dev/null 2>&1; then
  echo "Installing Obsidian (Flatpak)..."
  sudo -u "$REAL_USER" flatpak install -y flathub md.obsidian.Obsidian || true
fi

# SSH setup
sudo -u "$REAL_USER" mkdir -p "$HOME_DIR/.ssh"
chmod 700 "$HOME_DIR/.ssh"
if [[ ! -f "$HOME_DIR/.ssh/id_ed25519" ]]; then
  sudo -u "$REAL_USER" ssh-keygen -t ed25519 -N "" -f "$HOME_DIR/.ssh/id_ed25519"
else
  chmod 600 "$HOME_DIR/.ssh/id_ed25519"
  chmod 644 "$HOME_DIR/.ssh/id_ed25519.pub" || true
fi

# Hostname
hostnamectl set-hostname "mole"

# Git config
echo "Setting git config variables"
sudo -u "$REAL_USER" git config --global user.name "Jack Hansen"
sudo -u "$REAL_USER" git config --global user.email "jackvwh@hotmail.com"
sudo -u "$REAL_USER" git config --global push.autoSetupRemote true
sudo -u "$REAL_USER" git config --global gpg.format ssh
sudo -u "$REAL_USER" git config --global user.signingkey "$HOME_DIR/.ssh/id_ed25519"
sudo -u "$REAL_USER" git config --global commit.gpgsign true

# AWS SSM Session Manager Plugin
if ! has session-manager-plugin; then
  pac_install session-manager-plugin || { if has pamac; then pamac build --no-confirm session-manager-plugin || true; fi; }
fi

# Aliases
echo "Setting custom aliases..."
{
  echo ""
  echo "# === Manjaro convenience aliases ==="
  echo "alias update='sudo pacman -Syu --noconfirm'"
  echo "alias install='sudo pacman -S --needed --noconfirm'"
  echo "alias remove='sudo pacman -Rns --noconfirm'"
  echo "alias search='pacman -Ss'"
  echo "alias files='pacman -Ql'"
} | sudo -u "$REAL_USER" tee -a "$TARGET_BASHRC" >/dev/null

# Ownership fixups
chown -R "$REAL_USER":"$REAL_USER" "$HOME_DIR/.ssh" || true

echo "Installation complete. A reboot is required for Docker group changes to take effect."
read -r -p "Would you like to reboot now? (y/N): " response
if [[ "${response,,}" =~ ^y(es)?$ ]]; then
  echo "Rebooting the system..."
  reboot
else
  echo "Please remember to reboot your system later to apply all changes."
fi
