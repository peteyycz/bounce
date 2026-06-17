# bounce

A standalone Qt6/QML email client with a translucent "liquid glass"
look, borrowed from the [hare](https://github.com/peteyycz/hare)
Hyprland shell. Backed by the Gmail REST API; eventually a full
multi-account client.

> Status: early.

## Get bounce

Signed, prebuilt binaries (Mac App Store / Microsoft Store / Flathub
Verified / direct download) are the planned paid distribution channel —
not live yet. Until then, build from source (see [Build](#build) below);
that path is free and stays free under AGPL-3.0.

## Support development

bounce is AGPL'd and built in the open. If you self-build and want
to chip in:

- **GitHub Sponsors** → <https://github.com/sponsors/peteyycz>
- One-time tips via Ko-fi / Liberapay — links land in the repo as
  those accounts get set up.

Donations don't unlock anything in the app — there's no two-tier
build, no nag screen, no license key. Paid official builds (above)
are how the project earns money once they ship; donations are how
self-builders say thanks.

## Stack

- **Qt 6** (Quick, Network, NetworkAuth, Keychain) — UI + HTTP + OAuth.
- **QML** for all UI. C++ is kept minimal — only what isn't reachable
  from QML
- **CMake + Ninja** for the build.
- **Nix flake** for a reproducible dev shell.

## Build

You need Nix with flakes enabled. Everything else (Qt6, qmllint,
qtkeychain, …) comes from the flake.

```sh
direnv allow                    # one-time, picks up .envrc + flake.nix
cmake -B build -G Ninja
cmake --build build
./build/bounce
```

Or, without direnv:

```sh
nix develop
cmake -B build -G Ninja && cmake --build build && ./build/bounce
```

Subsequent edits: just `cmake --build build`. QML is bundled into the
binary via `qml.qrc`; `QML_DISABLE_DISK_CACHE=1` is set programmatically
in `main.cpp` during development so QML edits always pick up fresh.

## Google OAuth credentials

OAuth credentials are **baked into the binary at configure time** —
nothing is read from disk at runtime.

If you need dev credentials:

1. Google Cloud Console → create a project → enable the **Gmail API**.
2. APIs & Services → Credentials → Create OAuth client ID → **Desktop app**.
3. Download the JSON and drop it at `./credentials.json` in the repo
   root. It's gitignored.
4. Reconfigure:
   ```sh
   cmake -B build -G Ninja && cmake --build build
   ```

To point CMake at a JSON elsewhere:
`cmake -B build -G Ninja -DBOUNCE_CREDENTIALS_FILE=/path/to/x.json`.

If no credentials file is found at configure time, CMake warns, the
binary still builds, and the Sign-in button stays disabled with an
explanatory status message.

### Scopes & re-auth

Adding a new scope (e.g. `gmail.readonly`) invalidates the stored
refresh token — it only grants the scopes that were authorized when
it was issued. After bumping scopes:

```sh
secret-tool clear service bounce key google_refresh_token
./build/bounce      # click Sign in → fresh consent screen
```

## Refresh-token storage

Tokens are kept in the **native keychain** via libsecret /
gnome-keyring / KWallet under service `bounce`, key
`google_refresh_token`. No JSON-on-disk token caching.

Inspect / nuke:

```sh
secret-tool search service bounce
secret-tool clear  service bounce key google_refresh_token
```

## Editor / LSP setup

CMake's `CMAKE_EXPORT_COMPILE_COMMANDS` writes a
`build/compile_commands.json`, symlinked at the repo root. On NixOS,
the gcc wrapper injects implicit include paths (Qt, libstdc++, glibc)
via `NIX_CFLAGS_COMPILE` that aren't visible to clangd outside the
Nix shell. CMake generates a `.clangd` file (gitignored) at configure
time that adds those paths back via `CompileFlags.Add`. Reconfigure
regenerates it whenever Nix store hashes change.

If clangd misreads Qt's `QStringLiteral` / `QByteArray` / etc.
template machinery, the `.clangd` also suppresses a small list of
`ovl_no_viable_*` diagnostics. The build itself catches genuine
overload errors, so the trade-off is reasonable.

For QML, `qmlls` is in the dev shell and honours `QML_IMPORT_PATH`
(set by the flake) so it resolves `import QtQuick` etc.

## License

[AGPL-3.0](LICENSE). If you modify bounce and ship it (binary or
network-hosted), you must publish your changes under the same license.

If those terms don't fit your use case, the copyright holder can grant
a commercial license — open an issue.
