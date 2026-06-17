# bounce

Standalone Qt6/QML desktop email client with a "liquid glass" aesthetic
borrowed from the [hare](../hare) Hyprland shell. End goal: a Gmail client
backed by the Gmail REST API + OAuth, replacing the current mock data.

## Stack

- **Qt 6** (`qtbase`, `qtdeclarative`, `qt5compat`) — UI runtime.
- **QML / QtQuick** — all UI, including layout, animation, styling.
  Almost everything is in `.qml`; C++ is kept to the bare minimum.
- **C++17** — only `src/main.cpp` (~25 lines). Boots a `QGuiApplication` +
  `QQmlApplicationEngine`, requests an alpha buffer for the transparent
  window surface, prints QML warnings, loads `qrc:/qml/main.qml`.
- **CMake + Ninja** — build. QML files are bundled into the binary via
  `qml.qrc` (AUTORCC).
- **Nix flake** — pinned dev shell + package output. `direnv` integration
  via `.envrc` (`use flake`).
- **Symbols Nerd Font** — icon glyphs. We map Lucide icon names →
  codepoints in `Theme.glyph`. No SVG bundling.

## Build & run

```sh
direnv allow                # one-time
cmake -B build -G Ninja
cmake --build build
./build/bounce
```

## Google OAuth setup

Credentials are **baked in at configure time**, not read at runtime:

1. Google Cloud Console → project → enable **Gmail API**.
2. Credentials → Create OAuth client ID → **Desktop app** → download JSON.
3. Drop it at `./credentials.json` (gitignored) and build:
   ```sh
   cmake -B build -G Ninja && cmake --build build
   ```
   To point CMake elsewhere instead:
   `cmake -B build -G Ninja -DBOUNCE_CREDENTIALS_FILE=/path/to/x.json`.

CMake parses the JSON, generates `build/generated/Credentials.h` with the
values as `#define`s, and `GoogleAuth.cpp` uses them. No JSON is read at
runtime. If no file exists at configure time, CMake warns, the binary
still builds, and the Sign-in button stays disabled with an explanatory
status message.

Flow: `Sign in` → system browser opens Google consent → Google redirects
to `http://127.0.0.1:<random>/` → our loopback handler captures the code
→ Qt exchanges it for tokens → we hit `/userinfo` for name + email.

Refresh tokens are stored in the **native keychain** (libsecret /
GNOME Keyring / KWallet via the Secret Service API) under service
`bounce`, key `google_refresh_token`. On startup `GoogleAuth` does a
keychain read; if it finds a token it calls `refreshTokens()` and
the user lands signed in. Sign-out deletes the entry.

Inspect manually:
```sh
secret-tool search service bounce
secret-tool clear  service bounce key google_refresh_token   # nuke
```

**Scope change ⇒ re-auth.** When we add a new scope (e.g. when
`gmail.readonly` was first wired), a stored refresh token still grants
only the old scopes. Calls return 403 with `insufficient_scope`. Force a
fresh sign-in: `secret-tool clear service bounce key google_refresh_token`
then launch the app and click Sign in.

## Mail data flow

`GmailService` (C++) holds a `QNetworkAccessManager` and watches
`GoogleAuth::authenticatedChanged`. On sign-in it calls
`users.messages.list?labelIds=INBOX&maxResults=50`, then issues parallel
`messages.get?format=metadata` GETs per ID, collects them in arrival
order, sorts back into the list order, and exposes them as `messages`.

Wired to QML as `Bounce.Mail.GmailService` (C++ singleton) and exposed
via the thin façade `Services.Inbox` so `MessageList` just binds
`model_: Inbox.messages`.

`QML_DISABLE_DISK_CACHE=1` is set programmatically in `main.cpp` during
development so QML edits always pick up fresh — drop that line before
shipping a release build.

## Layout

```
src/main.cpp            # Qt entry point (minimal)
CMakeLists.txt          # Qt6::Quick + qrc
qml.qrc                 # bundles QML + assets into the binary
flake.nix / .envrc      # dev shell + reproducible build
qml/
├── main.qml            # Window (transparent, frameless) + MailWindow
├── Theme/Theme.qml     # Singleton: colors, geometry, motion, glyph map
├── Common/             # Shared primitives (currently just GlassSurface)
├── Mail/               # The three-pane mail UI + Compose overlay
│   ├── MailWindow.qml  # composes the three panes + Compose overlay
│   ├── Sidebar.qml / NavItem.qml
│   ├── MessageList.qml / MessageRow.qml
│   ├── ReadingPane.qml / ThreadMessage.qml
│   ├── Compose.qml
│   ├── Avatar.qml / Chip.qml / Icon.qml / IconButton.qml
│   └── MockData.qml    # Singleton — hard-coded inbox + thread, no I/O yet
└── assets/wallpaper.jpg   # currently unused (window is transparent)
```

## Design notes

- **Liquid glass** = translucent dark fill (`Theme.bg = #18181c at low α`)
  inside a rounded rectangle. No real backdrop-filter blur — Qt Quick
  can't do that in-shader cheaply. We rely on the **compositor** (e.g.
  Hyprland's `blur`) to blur whatever's behind the transparent window
  surface. The Window asks for an alpha buffer (`QSurfaceFormat` in
  `main.cpp`) and is `color: "transparent"` + `FramelessWindowHint`.
- **Hare comparison**: hare is a Quickshell-based desktop shell; bounce
  is a standalone Qt app reusing hare's visual vocabulary (`Theme.qml`
  palette + geometry, `GlassSurface` primitive) but not its Wayland /
  layer-shell plumbing.
- **Mock data only** for now. Replacing `MockData.qml` with real Gmail
  data is the next big chunk: OAuth (installed-app flow), HTTP via
  `QNetworkAccessManager`, polling `users.history.list` for push-like
  updates, MIME assembly for send.

## Conventions

- All colors / sizes / animation curves live in `qml/Theme/Theme.qml` —
  no hex literals in component files.
- One component per file. Files named after their root type.
- `font.pixelSize` is an int — don't use fractional literals (Qt rounds
  them silently in some versions and rejects them in others, taking the
  whole component down with it).
- `Item.palette` exists in Qt 6, so avoid `property … palette` on
  Item-derived components. Use `paletteIndex` etc.
