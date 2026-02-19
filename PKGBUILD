# Maintainer: Jaewoo Joung
pkgname=blunux-installer
pkgver=0.1.0
pkgrel=1
pkgdesc='Blunux Package Installer'
arch=('x86_64')
url='https://github.com/nidoit/appinstaller'
license=('MIT')
depends=('webkit2gtk-4.1' 'libayatana-appindicator' 'librsvg')
makedepends=('rust' 'cargo' 'nodejs' 'npm' 'openssl' 'appmenu-gtk-module')
source=("$pkgname-$pkgver.tar.gz")
sha256sums=('SKIP')

build() {
    cd "$srcdir/$pkgname-$pkgver"
    npm install
    npx tauri build --no-bundle
}

package() {
    cd "$srcdir/$pkgname-$pkgver"
    install -Dm755 "src-tauri/target/release/$pkgname" "$pkgdir/usr/bin/$pkgname"
    install -Dm644 "src-tauri/icons/icon.png" "$pkgdir/usr/share/pixmaps/$pkgname.png"
    install -Dm644 "$pkgname.desktop" "$pkgdir/usr/share/applications/$pkgname.desktop"
}
