import QtQuick
import Theme 1.0

// Circular gradient avatar. `palette` is an int index 0..5, or -1 for
// the lavender accent variant. `initials` is the 2-letter label inside.
Item {
    id: root
    property int paletteIndex: 0
    property string initials: ""
    property int size: 40
    property int fontSize: 14

    width: size
    height: size

    readonly property var swatch: paletteIndex < 0 ? Theme.avatarAccent : Theme.avatars[paletteIndex % Theme.avatars.length]

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: root.swatch.a }
            GradientStop { position: 1.0; color: root.swatch.b }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.initials
        color: root.swatch.ink
        font.family: Theme.fonts.sans
        font.pixelSize: root.fontSize
        font.weight: Font.DemiBold
    }
}
