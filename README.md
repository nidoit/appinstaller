# Blunux Installer

A Tauri-based GUI for installing packages from your GitHub scripts repo with a single sudo password prompt.

## Features
- ✅ Enter sudo password **once** — cached for the entire session
- ✅ Click package cards to select, click Install to run all
- ✅ Live log output in right panel
- ✅ Sequential installation queue
- ✅ Per-card status (installing / done / failed)
- ✅ All scripts fetched from `https://raw.githubusercontent.com/JaewooJoung/linux/main/`

## Quick Start

```bash
bash setup-and-run.sh
```

Or manually:
```bash
npm install
npm run dev       # development
npm run build     # production .AppImage/.deb
```

## Adding More Packages

Edit `src/index.html`, find the `PACKAGES` object and add entries:

```js
{ id: 'myapp', name: 'MyApp', desc: 'Description', icon: '🚀', script: 'myapp.sh' },
```

The `script` value must match the filename in your GitHub repo.

## Requirements
- Arch Linux / Blunux
- Rust (auto-installed by setup script)
- Node.js + npm (`yay -S nodejs npm`)
- webkit2gtk-4.1 (auto-installed by setup script)
