#!/bin/bash
# ─────────────────────────────────────────────────────
#  Blunux Installer - Setup & Launch
# ─────────────────────────────────────────────────────
set -e

echo "==> Checking dependencies..."

# Check Rust
if ! command -v cargo &>/dev/null; then
  echo "Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
fi

# Check Node
if ! command -v node &>/dev/null; then
  echo "ERROR: Node.js is required. Install with: yay -S nodejs npm"
  exit 1
fi

# Check Tauri system deps (Arch/Blunux)
echo "==> Installing Tauri system dependencies..."
sudo pacman -S --needed --noconfirm \
  webkit2gtk-4.1 \
  base-devel \
  curl \
  wget \
  openssl \
  appmenu-gtk-module \
  libayatana-appindicator \
  librsvg 2>/dev/null || true

echo "==> Installing npm packages..."
npm install

echo "==> Launching Blunux Installer..."
npm run dev
