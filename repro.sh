#!/usr/bin/env bash
# Shows that `proto install` gives a Rust toolchain without rustc and cargo
# when the folder has a rust-toolchain.toml. Run it in a clean ubuntu:24.04 container.
set -euo pipefail

apt-get update -qq >/dev/null
apt-get install -y -qq curl ca-certificates git xz-utils >/dev/null

# rustup with a default toolchain, as on GitHub's ubuntu-latest runner.
curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable >/dev/null 2>&1
curl -fsSL https://moonrepo.dev/install/proto.sh | bash -s -- 0.64.1 --yes >/dev/null 2>&1
export PATH="$HOME/.proto/shims:$HOME/.proto/bin:$HOME/.cargo/bin:$PATH"

# Print the versions outside /work. In /work, rustup --version installs the toolchain
# that rust-toolchain.toml selects, and the bug does not occur.
proto --version
rustup --version 2>/dev/null

mkdir -p /work && cd /work
printf 'rust = "1.91.0"\n' > .prototools
# To test a build of the plugin, give its URL, for example RUST_PLUGIN=file:///repro/rust_tool.wasm.
if [ -n "${RUST_PLUGIN:-}" ]; then
  printf '[plugins.tools]\nrust = "%s"\n' "$RUST_PLUGIN" >> .prototools
  proto trust .prototools
fi
printf '[toolchain]\nchannel = "1.91.0"\ncomponents = ["clippy"]\nprofile = "minimal"\n' > rust-toolchain.toml

proto install

echo "Binaries in the toolchain:"
ls "$HOME/.rustup/toolchains/1.91.0-x86_64-unknown-linux-gnu/bin"

if [ -x "$HOME/.rustup/toolchains/1.91.0-x86_64-unknown-linux-gnu/bin/cargo" ]; then
  echo "OK: the toolchain has cargo."
else
  echo "BUG: the toolchain has no cargo."
  exit 1
fi
