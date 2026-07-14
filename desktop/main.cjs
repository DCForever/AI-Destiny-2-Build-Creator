/**
 * Electron thin shell for Destiny2BuildCreator.
 *
 * Spawns the Next.js standalone sidecar on plain Node (not Electron's ABI)
 * and loads it in a BrowserWindow. See docs/packaging-desktop.md.
 *
 * Spike:
 *   npm run build && bash scripts/prepare-standalone.sh
 *   npm i -D electron
 *   npm run spike:electron
 */

const { app, BrowserWindow, dialog } = require("electron");
const { spawn } = require("node:child_process");
const fs = require("node:fs");
const http = require("node:http");
const path = require("node:path");

const PREFERRED_PORT = Number(process.env.D2BC_PORT || 3000);
const HOST = "127.0.0.1";
const READY_TIMEOUT_MS = 60_000;
const READY_POLL_MS = 250;

/** @type {import('node:child_process').ChildProcess | null} */
let serverProcess = null;
/** @type {BrowserWindow | null} */
let mainWindow = null;
let shuttingDown = false;

function standaloneRoot() {
  if (process.env.D2BC_STANDALONE_DIR) {
    return path.resolve(process.env.D2BC_STANDALONE_DIR);
  }
  if (app.isPackaged) {
    return path.join(process.resourcesPath, "standalone");
  }
  return path.join(__dirname, "..", ".next", "standalone");
}

function cacheRoot() {
  return process.env.D2BC_CACHE_ROOT || path.join(app.getPath("userData"), "cache");
}

function waitForReady(port, timeoutMs) {
  const started = Date.now();
  return new Promise((resolve, reject) => {
    const attempt = () => {
      const req = http.get({ host: HOST, port, path: "/", timeout: 1000 }, (res) => {
        res.resume();
        resolve();
      });
      req.on("error", () => {
        if (Date.now() - started > timeoutMs) {
          reject(new Error(`Sidecar did not become ready on http://${HOST}:${port}`));
          return;
        }
        setTimeout(attempt, READY_POLL_MS);
      });
    };
    attempt();
  });
}

function startSidecar(port) {
  const root = standaloneRoot();
  const entry = path.join(root, "server.js");
  if (!fs.existsSync(entry)) {
    return Promise.reject(
      new Error(
        `Missing standalone server at ${entry}. Run npm run build && bash scripts/prepare-standalone.sh`,
      ),
    );
  }

  const dataDir = cacheRoot();
  fs.mkdirSync(dataDir, { recursive: true });

  const env = {
    ...process.env,
    NODE_ENV: "production",
    HOSTNAME: HOST,
    PORT: String(port),
    D2BC_CACHE_ROOT: dataDir,
  };

  // Always use PATH `node` so better-sqlite3 matches Node's ABI, not Electron's.
  serverProcess = spawn("node", [entry], {
    cwd: root,
    env,
    stdio: ["ignore", "pipe", "pipe"],
    windowsHide: true,
    shell: process.platform === "win32",
  });

  serverProcess.stdout?.on("data", (chunk) => {
    process.stdout.write(`[sidecar] ${chunk}`);
  });
  serverProcess.stderr?.on("data", (chunk) => {
    process.stderr.write(`[sidecar] ${chunk}`);
  });

  return new Promise((resolve, reject) => {
    const onEarlyExit = (code, signal) => {
      serverProcess = null;
      if (!shuttingDown) {
        reject(new Error(`Sidecar exited early (${signal || code})`));
      }
    };
    serverProcess.once("error", reject);
    serverProcess.once("exit", onEarlyExit);
    waitForReady(port, READY_TIMEOUT_MS)
      .then(() => {
        serverProcess?.off("exit", onEarlyExit);
        serverProcess?.on("exit", (code, signal) => {
          serverProcess = null;
          if (!shuttingDown && mainWindow && !mainWindow.isDestroyed()) {
            dialog.showErrorBox(
              "Destiny 2 Build Creator",
              `The local server exited unexpectedly (${signal || code}).`,
            );
            app.quit();
          }
        });
        resolve();
      })
      .catch(reject);
  });
}

function stopSidecar() {
  if (!serverProcess || serverProcess.killed) {
    shuttingDown = true;
    return;
  }
  shuttingDown = true;
  const child = serverProcess;
  serverProcess = null;
  try {
    child.kill("SIGTERM");
  } catch {
    // ignore
  }
  setTimeout(() => {
    if (!child.killed) {
      try {
        child.kill("SIGKILL");
      } catch {
        // ignore
      }
    }
  }, 3000);
}

function createWindow(port) {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 840,
    webPreferences: {
      preload: path.join(__dirname, "preload.cjs"),
      contextIsolation: true,
      nodeIntegration: false,
    },
    title: "Destiny 2 Build Creator",
  });
  mainWindow.loadURL(`http://${HOST}:${port}`);
  mainWindow.on("closed", () => {
    mainWindow = null;
  });
}

async function boot() {
  try {
    await startSidecar(PREFERRED_PORT);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error(message);
    if (process.env.D2BC_SPIKE_HEADLESS !== "1") {
      dialog.showErrorBox("Destiny 2 Build Creator", message);
    }
    stopSidecar();
    app.exit(1);
    return;
  }

  if (process.env.D2BC_SPIKE_HEADLESS === "1") {
    console.log(
      JSON.stringify({
        ok: true,
        port: PREFERRED_PORT,
        cacheRoot: cacheRoot(),
        standaloneRoot: standaloneRoot(),
      }),
    );
    stopSidecar();
    setTimeout(() => app.exit(0), 500);
    return;
  }

  createWindow(PREFERRED_PORT);
}

app.whenReady().then(boot);

app.on("before-quit", () => {
  stopSidecar();
});

app.on("window-all-closed", () => {
  stopSidecar();
  app.quit();
});
