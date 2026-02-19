#!/bin/bash
# ─────────────────────────────────────────────────────
#  Blunux Installer - Build pacman package
# ─────────────────────────────────────────────────────
set -e

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"
PKGNAME="blunux-installer"
PKGVER="0.1.0"

# ── Install yay if not present ──
if ! command -v yay &>/dev/null; then
    echo "==> Installing yay..."
    YAYDIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$YAYDIR/yay-bin"
    cd "$YAYDIR/yay-bin"
    makepkg -si --noconfirm
    cd "$SCRIPTDIR"
    rm -rf "$YAYDIR"
fi

# ── Install build dependencies ──
echo "==> Installing build dependencies..."
sudo pacman -S --needed --noconfirm \
    webkit2gtk-4.1 \
    base-devel \
    curl \
    wget \
    openssl \
    appmenu-gtk-module \
    libayatana-appindicator \
    librsvg \
    rust \
    nodejs \
    npm 2>/dev/null || true

# ── Create build directory ──
BUILDDIR=$(mktemp -d)
echo "==> Build directory: $BUILDDIR"

# ── Create source tarball from local source ──
echo "==> Creating source archive..."
tar czf "$BUILDDIR/$PKGNAME-$PKGVER.tar.gz" \
    --transform "s,^\\.,$PKGNAME-$PKGVER," \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='src-tauri/target' \
    -C "$SCRIPTDIR" .

# ── Copy PKGBUILD and build ──
cp "$SCRIPTDIR/PKGBUILD" "$BUILDDIR/"
cd "$BUILDDIR"

echo "==> Building package with makepkg..."
makepkg -sf --noconfirm

# ── Show result ──
PKG=$(find "$BUILDDIR" -maxdepth 1 -name "*.pkg.tar.*" -not -name "*.sig" | head -1)

echo ""
echo "─────────────────────────────────────────────────────"
if [ -n "$PKG" ]; then
    cp "$PKG" "$SCRIPTDIR/"
    PKGFILE="$SCRIPTDIR/$(basename "$PKG")"
    echo "  Build complete!"
    echo "  Package: $PKGFILE"
    echo ""
    echo "  Install with:"
    echo "    sudo pacman -U \"$PKGFILE\""
    echo ""
    echo "  Then run:"
    echo "    blunux-installer"
else
    echo "  Build finished but package not found."
    echo "  Check: $BUILDDIR"
fi
echo "─────────────────────────────────────────────────────"
