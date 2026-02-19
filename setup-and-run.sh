#!/bin/bash
# ─────────────────────────────────────────────────────
#  Blunux Installer - Build AppImage
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
  librsvg \
  squashfs-tools \
  fuse2 2>/dev/null || true

# Check appimagetool (required by Tauri for AppImage bundling)
if ! command -v appimagetool &>/dev/null; then
  echo "==> Installing appimagetool..."
  sudo wget -q "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" \
    -O /usr/local/bin/appimagetool
  sudo chmod +x /usr/local/bin/appimagetool
  echo "    appimagetool installed at /usr/local/bin/appimagetool"
fi

echo "==> Installing npm packages..."
npm install

echo "==> Building AppImage..."
npx tauri build --bundles appimage

# Find built AppImage
APPIMAGE=$(find src-tauri/target/release/bundle/appimage -name "*.AppImage" 2>/dev/null | head -1)

echo ""
echo "─────────────────────────────────────────────────────"
if [ -n "$APPIMAGE" ]; then
  echo "  Build complete!"
  echo "  AppImage: $APPIMAGE"
  echo ""
  echo "  Run with:"
  echo "    chmod +x \"$APPIMAGE\""
  echo "    .\"/$APPIMAGE\""
else
  echo "  Build finished but AppImage not found."
  echo "  Check: src-tauri/target/release/bundle/appimage/"
fi
echo "─────────────────────────────────────────────────────"
