#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Blunux Installer - Payload Install Script
#  Runs inside the extracted .run archive to install the app on the system.
# ─────────────────────────────────────────────────────────────────────────────
set -e

APPNAME="blunux-installer"
INSTALL_DIR="/opt/$APPNAME"
BIN_LINK="/usr/local/bin/$APPNAME"
ICON_DIR="/usr/share/pixmaps"
DESKTOP_DIR="/usr/share/applications"

# Directory containing this script (the extracted payload)
PAYLOAD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Blunux Installer - System Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Escalate to root if needed ──────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo "==> Root access is required for installation."
    echo "    Re-running with sudo..."
    exec sudo bash "${BASH_SOURCE[0]}" "$@"
fi

# ── Detect package manager and install runtime dependencies ─────────────────
echo "==> Checking runtime dependencies..."

if command -v pacman &>/dev/null; then
    pacman -S --needed --noconfirm \
        webkit2gtk-4.1 \
        libayatana-appindicator \
        librsvg 2>/dev/null || true

elif command -v apt-get &>/dev/null; then
    apt-get install -y --no-install-recommends \
        libwebkit2gtk-4.1-0 \
        libayatana-appindicator3-1 \
        librsvg2-2 2>/dev/null || true

elif command -v dnf &>/dev/null; then
    dnf install -y \
        webkit2gtk4.1 \
        libayatana-appindicator \
        librsvg2 2>/dev/null || true
else
    echo "  [warn] Could not detect package manager."
    echo "         Please ensure webkit2gtk-4.1, libayatana-appindicator,"
    echo "         and librsvg are installed."
fi

# ── Install application ──────────────────────────────────────────────────────
echo "==> Installing $APPNAME to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp "$PAYLOAD_DIR/$APPNAME" "$INSTALL_DIR/$APPNAME"
chmod +x "$INSTALL_DIR/$APPNAME"

# Install uninstall script alongside the app
cp "$PAYLOAD_DIR/uninstall.sh" "$INSTALL_DIR/uninstall.sh"
chmod +x "$INSTALL_DIR/uninstall.sh"

# Create symlink in PATH
ln -sf "$INSTALL_DIR/$APPNAME" "$BIN_LINK"

# ── Install icon ─────────────────────────────────────────────────────────────
if [ -f "$PAYLOAD_DIR/icon.png" ]; then
    echo "==> Installing icon..."
    install -Dm644 "$PAYLOAD_DIR/icon.png" "$ICON_DIR/$APPNAME.png"
fi

# ── Install desktop entry ────────────────────────────────────────────────────
if [ -f "$PAYLOAD_DIR/$APPNAME.desktop" ]; then
    echo "==> Installing desktop entry..."
    install -Dm644 "$PAYLOAD_DIR/$APPNAME.desktop" "$DESKTOP_DIR/$APPNAME.desktop"
    # Update desktop database if available
    command -v update-desktop-database &>/dev/null && \
        update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installation complete!"
echo ""
echo "  Launch from terminal : $APPNAME"
echo "  Or open from your application menu."
echo ""
echo "  To uninstall:"
echo "    sudo $INSTALL_DIR/uninstall.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Launch as the original non-root user ─────────────────────────────────────
REAL_USER="${SUDO_USER:-}"
if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
    echo "==> Launching $APPNAME as '$REAL_USER'..."
    sudo -u "$REAL_USER" "$BIN_LINK" &
fi
