#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Blunux Installer - Build Self-Extracting .run Installer
#
#  Usage: bash make-run-installer.sh
#
#  Output: blunux-installer.run
#          A single self-extracting executable — like VirtualBox's .run file.
#          When an end-user runs it, it installs the app and launches it.
#
#  How it works:
#    The .run file is a shell script header followed by a compressed tar
#    archive appended as binary data. The header extracts the archive into a
#    temp directory, then runs install.sh from inside it.
#
#    Structure of blunux-installer.run:
#      [bash header — finds + extracts payload, runs install.sh]
#      __PAYLOAD_BELOW__
#      [binary: tar.gz containing binary + icon + desktop + install.sh]
#
#  Note: Uses --no-bundle to produce a raw binary instead of an AppImage.
#        This avoids the linuxdeploy/FUSE dependency entirely.
# ─────────────────────────────────────────────────────────────────────────────
set -e

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"
APPNAME="blunux-installer"
OUTFILE="$SCRIPTDIR/$APPNAME.run"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Blunux Installer — Building .run installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Step 1: Install build dependencies ───────────────────────────────────────
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

# ── Step 2: Build the Tauri binary (no-bundle, avoids linuxdeploy/FUSE) ──────
echo "==> Installing npm dependencies..."
cd "$SCRIPTDIR"
npm install

echo "==> Building Tauri app (binary only, no AppImage)..."
NO_STRIP=true npx tauri build --no-bundle

# ── Step 3: Locate built binary ──────────────────────────────────────────────
BINARY_PATH="$SCRIPTDIR/src-tauri/target/release/$APPNAME"

if [ ! -f "$BINARY_PATH" ]; then
    echo "ERROR: Binary not found at $BINARY_PATH. Check the build output above."
    exit 1
fi

echo "==> Found: $BINARY_PATH"

# ── Step 4: Assemble payload directory ───────────────────────────────────────
PAYLOADDIR=$(mktemp -d /tmp/blunux-payload.XXXXXX)
trap 'rm -rf "$PAYLOADDIR"' EXIT

echo "==> Assembling payload..."
cp "$BINARY_PATH"                        "$PAYLOADDIR/$APPNAME"
cp "$SCRIPTDIR/src-tauri/icons/icon.png" "$PAYLOADDIR/icon.png"
cp "$SCRIPTDIR/$APPNAME.desktop"       "$PAYLOADDIR/$APPNAME.desktop"
cp "$SCRIPTDIR/install.sh"             "$PAYLOADDIR/install.sh"
chmod +x "$PAYLOADDIR/install.sh"

# ── Step 5: Create compressed payload tarball ─────────────────────────────────
echo "==> Compressing payload..."
PAYLOAD_TAR=$(mktemp /tmp/blunux-payload.XXXXXX.tar.gz)
tar czf "$PAYLOAD_TAR" -C "$PAYLOADDIR" .

# ── Step 6: Write the .run header (self-extracting shell script) ──────────────
#
#  The header locates the __PAYLOAD_BELOW__ marker line in itself,
#  extracts everything after it as a tar.gz stream, and runs install.sh.
#  This is the same technique used by makeself and VirtualBox's .run files.
#
echo "==> Writing .run header..."
cat > "$OUTFILE" << 'RUN_HEADER'
#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Blunux Installer — Self-Extracting Installer
#
#  Usage:
#    chmod +x blunux-installer.run
#    ./blunux-installer.run
#
#  This file is a shell script with a compressed archive appended after the
#  __PAYLOAD_BELOW__ marker. Running it extracts the archive to a temp
#  directory and executes the bundled install.sh.
# ─────────────────────────────────────────────────────────────────────────────

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Blunux Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "==> Extracting installer..."

# Locate the payload: the line immediately after __PAYLOAD_BELOW__
SKIP=$(awk '/^__PAYLOAD_BELOW__$/{print NR + 1; exit}' "$0")

if [ -z "$SKIP" ]; then
    echo "ERROR: Could not find payload marker in this file. The .run may be corrupt."
    exit 1
fi

# Create a temp directory; clean it up on exit
TMPDIR=$(mktemp -d /tmp/blunux-install.XXXXXX)
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

# Extract the binary payload (tail handles binary safely on GNU systems)
tail -n +"$SKIP" "$0" | tar xz -C "$TMPDIR"

if [ ! -f "$TMPDIR/install.sh" ]; then
    echo "ERROR: install.sh not found in extracted payload."
    exit 1
fi

chmod +x "$TMPDIR/install.sh"

echo "==> Running installer..."
"$TMPDIR/install.sh" "$@"
EXIT_CODE=$?

exit $EXIT_CODE

__PAYLOAD_BELOW__
RUN_HEADER

# ── Step 7: Append the binary payload ────────────────────────────────────────
#
#  The header above ends with a newline after __PAYLOAD_BELOW__.
#  We append the raw tar.gz bytes directly — no encoding needed.
#
echo "==> Appending compressed payload..."
cat "$PAYLOAD_TAR" >> "$OUTFILE"
rm -f "$PAYLOAD_TAR"

# Make the .run file executable
chmod +x "$OUTFILE"

# ── Done ──────────────────────────────────────────────────────────────────────
FILESIZE=$(du -sh "$OUTFILE" | cut -f1)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Build complete!"
echo ""
echo "  Installer : $OUTFILE"
echo "  Size      : $FILESIZE"
echo ""
echo "  Distribute blunux-installer.run to end users."
echo "  They install it with:"
echo ""
echo "    chmod +x blunux-installer.run"
echo "    ./blunux-installer.run"
echo ""
echo "  The installer will:"
echo "    1. Extract itself to a temp directory"
echo "    2. Install runtime dependencies (webkit2gtk, ...)"
echo "    3. Install the app to /opt/blunux-installer/"
echo "    4. Create a symlink at /usr/local/bin/blunux-installer"
echo "    5. Install the desktop entry and icon"
echo "    6. Launch the app"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
