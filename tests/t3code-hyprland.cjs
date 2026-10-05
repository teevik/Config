const assert = require("node:assert/strict");
const fs = require("node:fs/promises");
const os = require("node:os");
const path = require("node:path");
const vm = require("node:vm");

async function main() {
  const appRoot = path.join(process.env.T3CODE_DESKTOP_ROOT, "libexec/t3code");
  const dirname = path.join(appRoot, "apps/desktop/dist-electron");
  const source = await fs.readFile(path.join(dirname, "main.cjs"), "utf8");
  const dataHome = await fs.mkdtemp(path.join(os.tmpdir(), "t3-hyprland-test-"));
  try {
    // Exercise the installed setup implementation and its actual path selection.
    // Nix launches stock Electron with an app directory, so isPackaged is false.
    const environment = {
      appRoot,
      isPackaged: false,
      resourcesPath: "/unused-electron-resources",
      linuxApplicationsDir: path.join(dataHome, "applications"),
      resolveResourcePathCandidates: (relative) => [
        path.join(dirname, "../resources", relative),
        path.join(dirname, "../prod-resources", relative),
      ],
    };
    const functions = source.slice(
      source.indexOf("function hyprlandCaptureExecutable(paths) {"),
      source.indexOf("async function captureHyprlandWindow(paths, options) {"),
    );
    const setup = source.match(/HyprlandCaptureSetup = class \{[\s\S]*?\n\t\};/);
    const paths = source.match(/const hyprlandCapturePaths = \{[\s\S]*?\n\t\};/);
    assert.ok(functions && setup && paths, "Could not locate installed Hyprland setup");
    const context = vm.createContext({
      node_fs_promises: fs,
      node_path: path,
      node_os: os,
      node_child_process: require("node:child_process"),
      process,
      path,
      environment,
      HYPRLAND_CAPTURE_EXECUTABLE: "t3-hyprland-snap-shot",
    });
    await vm.runInContext(
      `${functions}\n${setup[0]}\n${paths[0]}\n` +
      'new HyprlandCaptureSetup(hyprlandCapturePaths).perform("install-hyprland-helper")',
      context,
    );
    const installed = path.join(dataHome, "t3code/hyprland-capture/t3-hyprland-snap-shot");
    const bundled = path.join(dirname, "../prod-resources/hyprland-capture/t3-hyprland-snap-shot");
    assert.deepEqual(await fs.readFile(installed), await fs.readFile(bundled));
    assert.ok((await fs.stat(installed)).mode & 0o111);
    console.log("PASS: installed desktop setup installs its bundled Hyprland helper");
  } finally {
    await fs.rm(dataHome, { recursive: true, force: true });
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
