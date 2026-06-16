import QtQuick
import Theme 1.0

// A Nerd-Font glyph keyed by Lucide-style name.
Text {
    property string name: ""
    property int size: 16
    text: name in Theme.glyph ? String.fromCharCode(Theme.glyph[name]) : ""
    font.family: Theme.fonts.icon
    font.pixelSize: size
    color: Theme.text
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
