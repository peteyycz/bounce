import QtQuick
import Theme 1.0

// Small coloured label pill. `kind` is one of "work", "news", "receipt",
// or anything else (falls back to the neutral fill/textDim pair).
Rectangle {
    id: root
    property string kind: ""
    property string label: ""
    property color overrideBg: "transparent"
    property color overrideFg: "transparent"

    readonly property var tint: Theme.chip(kind)
    readonly property color bgColor: overrideBg.a > 0 ? overrideBg : tint.bg
    readonly property color fgColor: overrideFg.a > 0 ? overrideFg : tint.fg

    implicitWidth: text.implicitWidth + 14
    implicitHeight: text.implicitHeight + 4
    radius: 5
    color: bgColor

    Text {
        id: text
        anchors.centerIn: parent
        text: root.label
        color: root.fgColor
        font.family: Theme.fonts.sans
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.1
    }
}
