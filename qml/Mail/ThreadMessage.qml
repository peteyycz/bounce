import QtQuick
import Theme 1.0

// A single message inside a thread. Open == expanded body; otherwise a
// one-line preview is shown next to the header.
Rectangle {
    id: root
    property var msg
    property bool open: msg ? msg.open : false

    width: parent ? parent.width : 0
    height: inner.implicitHeight + 2
    radius: Theme.rMd
    color: open ? Theme.fill : "transparent"
    border.color: Theme.hairline
    border.width: 1

    Column {
        id: inner
        width: parent.width
        spacing: 0

        // header row
        Item {
            id: mhd
            width: parent.width
            height: 70

            Avatar {
                id: ava
                x: 17; y: 15
                size: 40
                fontSize: 14
                paletteIndex: root.msg ? root.msg.palette : 0
                initials: root.msg ? root.msg.initials : ""
            }
            Column {
                x: ava.x + ava.width + 12
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - (whenText.width + 24)
                spacing: 1
                Text {
                    text: root.msg ? root.msg.from : ""
                    color: Theme.text
                    font.family: Theme.fonts.sans
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    width: parent.width
                }
                Text {
                    text: root.msg ? root.msg.to : ""
                    color: Theme.textDim
                    font.family: Theme.fonts.sans
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
            Text {
                id: whenText
                anchors.right: parent.right
                anchors.rightMargin: 17
                anchors.verticalCenter: parent.verticalCenter
                text: root.msg ? root.msg.when : ""
                color: Theme.textFaint
                font.family: Theme.fonts.sans
                font.pixelSize: 12
            }
        }

        // collapsed preview
        Text {
            visible: !root.open
            text: root.msg ? root.msg.preview : ""
            color: Theme.textDim
            font.family: Theme.fonts.sans
            font.pixelSize: 13
            leftPadding: 69
            rightPadding: 17
            bottomPadding: 15
            elide: Text.ElideRight
            width: parent.width
        }

        // expanded body
        Column {
            visible: root.open
            x: 22; width: parent.width - 44
            spacing: 15
            bottomPadding: 22
            topPadding: 4

            Repeater {
                model: root.msg ? root.msg.body : []
                delegate: Text {
                    text: modelData
                    color: Theme.text
                    font.family: Theme.fonts.sans
                    font.pixelSize: 15
                    lineHeight: 1.55
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }
            Text {
                visible: !!root.msg && !!root.msg.sig
                text: root.msg && root.msg.sig ? root.msg.sig : ""
                color: Theme.textDim
                font.family: Theme.fonts.sans
                font.pixelSize: 14
                lineHeight: 1.55
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }
    }
}
