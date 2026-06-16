import QtQuick
import QtQuick.Controls
import Theme 1.0

// Transparent square button with rounded hover fill — matches .iconbtn in mail.css.
Rectangle {
    id: root
    property string icon: ""
    property int iconSize: 18
    property real iconScale: 1.0
    property color hoverFill: Theme.fill
    property color baseColor: Theme.textDim
    property color hoverColor: Theme.text

    signal clicked()

    width: 36; height: 36
    radius: Theme.rSm
    color: ma.containsMouse ? hoverFill : "transparent"
    Behavior on color { ColorAnimation { duration: 140 } }

    Icon {
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize * root.iconScale
        color: ma.containsMouse ? root.hoverColor : root.baseColor
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
