const assert = require("node:assert/strict");
const { createRequire } = require("node:module");
const { join } = require("node:path");

// Resolve the same installed dependency as the desktop backend, using Electron's
// Node mode so Node.js cannot mask a missing libstdc++ dependency.
const serverRequire = createRequire(
  join(process.env.T3CODE_PACKAGE_ROOT, "libexec/t3code/apps/server/dist/bin.mjs"),
);
const pty = serverRequire("node-pty");
const terminal = pty.spawn(process.env.T3CODE_TEST_SHELL, [
  "-c",
  "printf t3code-native-ok",
]);
let output = "";
const timeout = setTimeout(() => {
  terminal.kill();
  throw new Error("Timed out waiting for the installed node-pty terminal");
}, 5000);
terminal.onData((data) => { output += data; });
terminal.onExit(({ exitCode }) => {
  clearTimeout(timeout);
  assert.equal(exitCode, 0);
  assert.equal(output, "t3code-native-ok");
  console.log("PASS: Electron loads installed node-pty and runs a terminal");
});
