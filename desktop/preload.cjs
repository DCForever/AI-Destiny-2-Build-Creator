/**
 * Minimal preload: contextIsolation on, no Node bridge yet.
 * First-run secrets UI can expose a narrow API here later.
 */
const { contextBridge } = require("electron");

contextBridge.exposeInMainWorld("d2bcDesktop", {
  isDesktop: true,
});
