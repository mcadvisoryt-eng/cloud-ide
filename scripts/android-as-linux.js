// android-as-linux.js
//
// Makes code-server treat Termux/Android as Linux, so it will install
// server-side extensions instead of refusing them.
//
// Why this is needed: Android is not a supported VS Code platform, so
// code-server reports process.platform === "android" and only offers "web"
// extensions. Pretending to be Linux lets the normal extensions install.
//
// Caveat: Android and Linux are not identical. Extensions that ship native
// (non-JavaScript) binaries, or that talk to the OS directly, may still fail.
// Use at your own risk — see docs/termux.md.
//
// Loaded via Node's --require, e.g.:
//   NODE_OPTIONS="--require $HOME/cloud-ide/scripts/android-as-linux.js" code-server

Object.defineProperty(process, "platform", {
  get() {
    return "linux";
  },
});
