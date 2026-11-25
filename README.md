# proto installs a Rust toolchain without rustc and cargo

`proto install` gives a Rust toolchain with no `rustc` and no `cargo` when the project has a `rust-toolchain.toml`. The toolchain has only the components and targets that the file lists. proto still reports success.

## Run

```sh
docker run --rm -v "$PWD:/repro:ro" ubuntu:24.04 bash /repro/repro.sh
```

Exit code 1 and `BUG: the toolchain has no cargo.` show the bug.

## Versions

- proto 0.64.1, with the `rust` plugin that it installs by default (`rust_tool` 0.14.0)
- rustup 1.29.3
- Ubuntu 24.04. GitHub's `ubuntu-latest` runner with `moonrepo/setup-toolchain` shows the same bug.

## Expected and actual behavior

- Expected: `~/.rustup/toolchains/1.91.0-x86_64-unknown-linux-gnu/bin` contains `cargo` and `rustc`.
- Actual: it contains only `cargo-clippy` and `clippy-driver`.

## Cause

1. proto creates the empty install folder `~/.rustup/toolchains/1.91.0-x86_64-unknown-linux-gnu` before it calls `native_install` of the plugin.
2. The plugin runs `rustup toolchain list` in the project. The project's `rust-toolchain.toml` selects 1.91.0, so rustup installs that toolchain. Because the folder exists, rustup treats the toolchain as installed. It adds only the components and targets of the file, and not the profile.
3. The plugin finds 1.91.0 in the list and a `bin` folder, so it does not run `rustup toolchain install`.

## Fix

Fix: https://github.com/moonrepo/plugins/pull/233 (issue: https://github.com/moonrepo/plugins/issues/232)

To test a build of the plugin, mount it and give its URL:

```sh
docker run --rm -v "$PWD:/repro:ro" -v "/path/to/rust_tool.wasm:/plugin/rust_tool.wasm:ro" \
  -e RUST_PLUGIN=file:///plugin/rust_tool.wasm ubuntu:24.04 bash /repro/repro.sh
```
