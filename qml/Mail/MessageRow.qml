import QtQuick
import Theme 1.0

// Delegate for one row in the message list.
Rectangle {
    id: root
    property var msg
    property bool active: false

    signal clicked()

    height: contentCol.implicitHeight + 24
    radius: Theme.rMd
    color: active ? Theme.fillStrong
                  : (ma.containsMouse ? Theme.fill : "transparent")
    Behavior on color { ColorAnimation { duration: 140 } }

    // accent indicator bar when active
    Rectangle {
        visible: root.active
        x: 3; y: 14
        width: 3
        height: parent.height - 28
        radius: 2
        color: Theme.accent
    }

    Avatar {
        id: ava
        x: 12; y: 12
        paletteIndex: msg.palette
        initials: msg.initials
        size: 40
        fontSize: 14
    }

    Column {
        id: contentCol
        x: ava.x + ava.width + 12
        y: 12
        width: parent.width - x - 12
        spacing: 2

        // line 1: from + time
        Item {
            width: parent.width
            height: Math.max(fromText.implicitHeight, timeText.implicitHeight)

            Text {
                id: fromText
                text: root.msg.from
                color: Theme.text
                font.family: Theme.fonts.sans
                font.pixelSize: 14
                font.weight: root.msg.unread ? Font.Bold : Font.DemiBold
                width: parent.width - timeText.implicitWidth - 8
                elide: Text.ElideRight
            }
            Text {
                id: timeText
                text: root.msg.time
                color: Theme.textFaint
                font.family: Theme.fonts.sans
                font.pixelSize: 12
                anchors.right: parent.right
                anchors.baseline: fromText.baseline
            }
        }

        // subject
        Text {
            text: root.msg.subject
            color: Theme.text
            font.family: Theme.fonts.sans
            font.pixelSize: 13
            font.weight: root.msg.unread ? Font.DemiBold : Font.Normal
            width: parent.width
            elide: Text.ElideRight
        }

        // snippet
        Text {
            text: root.msg.snippet
            color: Theme.textDim
            font.family: Theme.fonts.sans
            font.pixelSize: 13
            lineHeight: 1.4
            width: parent.width - (root.msg.starred || (!root.msg.unread && root.msg.starred === false) ? 0 : 0)
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            topPadding: 0
        }

        // chips
        Row {
            spacing: 6
            topPadding: 5
            Repeater {
                model: root.msg.chips
                delegate: Chip { kind: modelData.kind; label: modelData.label }
            }
        }
    }

    // unread dot (top-right)
    Rectangle {
        visible: root.msg.unread
        anchors.right: parent.right
        anchors.rightMargin: 13
        anchors.top: parent.top
        anchors.topMargin: 15
        width: 8; height: 8; radius: 4
        color: Theme.accent
    }

    // star (bottom-right)
    Icon {
        visible: !root.msg.unread
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        name: "star"
        size: 15
        color: root.msg.starred ? Theme.star : Theme.textFaint
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
