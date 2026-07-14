# Desktop shell (packaging spike)

Electron thin shell that starts the Next.js standalone sidecar. Full research: [docs/packaging-desktop.md](../docs/packaging-desktop.md).

## Spike on this machine

```bash
# from repo root
npm run build
bash scripts/prepare-standalone.sh
npm i -D electron          # once; large download
npm run spike:electron     # headless lifecycle proof
```

Interactive window (not headless):

```bash
npx electron desktop
```

## Windows NSIS (build machine with Windows or wine — prefer real Windows CI)

```bash
npm i -D electron electron-builder
npm run build
bash scripts/prepare-standalone.sh
npm run desktop:dist
```

Installer output: `dist/desktop/`.
