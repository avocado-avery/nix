#!/usr/bin/env bash
set -euo pipefail

# set sane path

export PATH=$PATH:/sbin/
if command -v adduser >/dev/null 2>&1; then
  echo "[*] adduser already installed"
else
  apt install adduser -y || yum install -y shadow-utils || dnf install -y shadow-utils || pacman -Syu --noconfirm shadow || zypper install -y shadow || apk add shadow
fi
echo "[*] Installing Nix (multi-user daemon mode)..."
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon --yes
# Enable flakes + new nix CLI
sudo mkdir -p /etc/nix
if ! grep -q "experimental-features" /etc/nix/nix.conf 2>/dev/null; then
  echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
fi

# Try to restart nix-daemon if available (not fatal if missing)
if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q nix-daemon.service; then
  sudo systemctl restart nix-daemon || true
fi

# Source profile to get nix in PATH right away
if [ -f /etc/profile.d/nix.sh ]; then
  echo "[*] Sourcing /etc/profile.d/nix.sh"
  # shellcheck disable=SC1091
  . /etc/profile.d/nix.sh
elif [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  echo "[*] Sourcing $HOME/.nix-profile/etc/profile.d/nix.sh"
  # shellcheck disable=SC1091
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
else
  echo "[!] Could not find nix profile script — you may need to open a new shell"
fi

# Verify installation
if command -v nix >/dev/null 2>&1; then
  echo "[*] Installed successfully:"
  nix --version
else
  echo "[!] nix still not in PATH — try 'source /etc/profile.d/nix.sh' or open a new shell"
fi
