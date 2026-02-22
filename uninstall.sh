#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Blunux Installer - Uninstall Script
#  Usage: sudo /opt/blunux-installer/uninstall.sh
#         or: ./blunux-appinst.run --uninstall
# ─────────────────────────────────────────────────────────────────────────────
set -e

APPNAME="blunux-installer"
INSTALL_DIR="/opt/$APPNAME"
BIN_LINK="/usr/local/bin/$APPNAME"
ICON="/usr/share/pixmaps/$APPNAME.png"
DESKTOP="/usr/share/applications/$APPNAME.desktop"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Blunux Installer - Uninstall"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Escalate to root if needed ───────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo "==> Root access is required."
    exec sudo bash "${BASH_SOURCE[0]}" "$@"
fi

# ── Confirm ──────────────────────────────────────────────────────────────────
read -r -p "==> Remove $APPNAME from this system? [y/N] " REPLY
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "  Aborted."
    exit 0
fi

# ── Remove files ─────────────────────────────────────────────────────────────
echo "==> Removing symlink: $BIN_LINK"
rm -f "$BIN_LINK"

echo "==> Removing desktop entry: $DESKTOP"
rm -f "$DESKTOP"
command -v update-desktop-database &>/dev/null && \
    update-desktop-database "/usr/share/applications" 2>/dev/null || true

echo "==> Removing icon: $ICON"
rm -f "$ICON"

echo "==> Removing app directory: $INSTALL_DIR"
rm -rf "$INSTALL_DIR"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  $APPNAME has been removed."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
