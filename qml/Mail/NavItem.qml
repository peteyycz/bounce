import QtQuick
import Theme 1.0

// One sidebar row. Either has an icon (regular item) or a coloured dot (label).
Rectangle {
    id: root
    property string icon: ""
    property color dot: "transparent"
    property string label: ""
    property string count: ""
    property bool active: false

    signal clicked()

    height: 32
    radius: Theme.rSm
    color: active ? Theme.accent
                  : (ma.containsMouse ? Theme.fill : "transparent")
    Behavior on color { ColorAnimation { duration: 140 } }

    readonly property color fg: active ? Theme.accentInk
                                        : (ma.containsMouse ? Theme.text : Theme.textDim)

    Row {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 11

        Item {
            width: 17
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter

            Icon {
                anchors.centerIn: parent
                visible: root.icon !== ""
                name: root.icon
                size: 17
                color: root.fg
            }
            Rectangle {
                anchors.centerIn: parent
                visible: root.dot.a > 0
                width: 9; height: 9; radius: 4.5
                color: root.dot
            }
        }

        Text {
            text: root.label
            color: root.fg
            font.family: Theme.fonts.sans
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            width: parent.width - 17 - (cnt.visible ? cnt.width + parent.spacing : 0) - parent.spacing
        }
    }

    Text {
        id: cnt
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: root.count
        visible: root.count !== ""
        color: root.active
               ? Qt.rgba(Theme.accentInk.r, Theme.accentInk.g, Theme.accentInk.b, 0.85)
               : Theme.textFaint
        font.family: Theme.fonts.sans
        font.pixelSize: 12
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
