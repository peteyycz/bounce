pragma Singleton

import QtQuick

// Liquid-glass palette + geometry. Standalone (no Quickshell/FileView):
// defaults are hard-coded; consumers may override `p` / `fonts` at runtime
// if they wire up a config loader later.
QtObject {
    id: root

    readonly property var p: ({
            bg: "18181c",
            bgAlpha: 0.10,
            surface: "27272a",
            ink: "ffffff",
            fillBase: "ffffff",
            fillAlpha: 0.08,
            fillStrongAlpha: 0.15,
            hairlineBase: "ffffff",
            hairlineAlpha: 0.10,
            border: "ffffff",
            borderAlpha: 0.14,
            accent: "c4a8c4",
            accentInk: "16121a",
            error: "e0533f"
        })

    readonly property var fonts: ({
            sans: "sans-serif",
            mono: "monospace",
            icon: "Symbols Nerd Font"
        })

    function rgba(hex, a) {
        return Qt.rgba(parseInt(hex.substr(0, 2), 16) / 255,
                       parseInt(hex.substr(2, 2), 16) / 255,
                       parseInt(hex.substr(4, 2), 16) / 255,
                       a);
    }

    // ---- colours ----
    readonly property color bg: rgba(p.bg, p.bgAlpha)
    readonly property color bgSolid: rgba(p.bg, 1)
    readonly property color text: rgba(p.ink, 0.92)
    readonly property color textDim: rgba(p.ink, 0.56)
    readonly property color textFaint: rgba(p.ink, 0.34)
    readonly property color fill: rgba(p.fillBase, p.fillAlpha)
    readonly property color fillStrong: rgba(p.fillBase, p.fillStrongAlpha)
    readonly property color hairline: rgba(p.hairlineBase, p.hairlineAlpha)
    readonly property color border: rgba(p.border, p.borderAlpha)
    readonly property color accent: "#" + p.accent
    readonly property color accentInk: "#" + p.accentInk
    readonly property color error: "#" + p.error

    // window traffic lights
    readonly property color dotRed: "#ec6a5e"
    readonly property color dotYellow: "#f4bf4f"
    readonly property color dotGreen: "#61c554"

    // star colour (for the gold-on flag)
    readonly property color star: "#e6b34d"

    // ---- avatar palette (matches glass.css .av-1 .. .av-6) ----
    // Each entry: gradient endpoints (top-left → bottom-right) + ink colour.
    readonly property var avatars: [
        { a: "#5b8def", b: "#3a64c8", ink: "#ffffff" },  // 0 / av-1
        { a: "#54b86a", b: "#2f8f4c", ink: "#ffffff" },  // 1 / av-2
        { a: "#a98ad6", b: "#7d5fc0", ink: "#ffffff" },  // 2 / av-3
        { a: "#e0a24e", b: "#c47e2c", ink: "#ffffff" },  // 3 / av-4
        { a: "#e07a8f", b: "#c14e6a", ink: "#ffffff" },  // 4 / av-5
        { a: "#4cb6c4", b: "#2f8b97", ink: "#ffffff" }   // 5 / av-6
    ]
    readonly property var avatarAccent: ({ a: "#c4a8c4", b: "#8a6f8a", ink: "#16121a" })

    // ---- label / chip tints ----
    // Background uses color-mix(base, transparent 80%) → ~0.2 alpha.
    // Foreground colour from the dark-theme branch of mail.css.
    function chip(kind) {
        if (kind === "work")    return { bg: Qt.rgba(0x5b/255, 0x8d/255, 0xef/255, 0.20), fg: "#7da6f5" };
        if (kind === "news")    return { bg: Qt.rgba(0x54/255, 0xb8/255, 0x6a/255, 0.20), fg: "#6fc985" };
        if (kind === "receipt") return { bg: Qt.rgba(0xe0/255, 0xa2/255, 0x4e/255, 0.20), fg: "#e9b56e" };
        return { bg: fillStrong, fg: textDim };
    }

    // ---- nav label dots (sidebar) ----
    readonly property var navDots: ({
            work: "#5b8def",
            news: "#54b86a",
            receipt: "#e0a24e"
        })

    // ---- geometry ----
    readonly property int rLg: 16
    readonly property int rMd: 12
    readonly property int rSm: 8
    readonly property int rPill: 999
    readonly property int gap: 11
    readonly property int pad: 14

    // ---- motion ----
    readonly property var emphasized: [0.05, 0, 0.133333, 0.06, 0.166667, 0.4, 0.208333, 0.82, 0.25, 1, 1, 1]
    readonly property int durFast: 200
    readonly property int durNormal: 350
    readonly property int durSlow: 500

    // ---- Nerd Font glyph map (Lucide icon name → codepoint) ----
    // Symbols Nerd Font (or any Nerd-patched font) provides Font Awesome /
    // Material Design Icons codepoints. These approximate the Lucide names
    // used in the design markup.
    readonly property var glyph: ({
            "inbox": 0xf01c,
            "star": 0xf005,
            "send": 0xf1d8,
            "file-text": 0xf15c,
            "archive": 0xf187,
            "shield-alert": 0xf071,
            "trash-2": 0xf2ed,
            "pencil-line": 0xf040,
            "search": 0xf002,
            "chevron-down": 0xf078,
            "chevron-up": 0xf077,
            "chevrons-up-down": 0xf0dc,
            "mail-open": 0xf2b6,
            "clock": 0xf017,
            "folder-input": 0xf07b,
            "reply": 0xf112,
            "reply-all": 0xf122,
            "paperclip": 0xf0c6,
            "image": 0xf03e,
            "smile": 0xf118,
            "link": 0xf0c1,
            "minus": 0xf068,
            "maximize-2": 0xf065,
            "x": 0xf00d,
            "log-out": 0xf08b
        })
}
