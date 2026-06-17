import QtQuick
import QtQuick.Controls
import Common 1.0
import Theme 1.0

// Middle pane: search + Inbox header + scrollable list.
Item {
    id: root
    property var model_: []
    property int currentIndex: 0
    signal rowClicked(int index)

    implicitWidth: 392

    // search bar + header
    Column {
        id: top
        x: 18; y: 16
        width: parent.width - 36
        spacing: 13

        Rectangle {
            id: searchBox
            width: parent.width
            height: 38
            radius: Theme.rPill
            color: Theme.fill
            border.color: Theme.hairline
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.leftMargin: 13
                anchors.rightMargin: 13
                spacing: 9

                Icon {
                    name: "search"; size: 16; color: Theme.textDim
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextField {
                    placeholderText: "Search mail"
                    color: Theme.text
                    placeholderTextColor: Theme.textFaint
                    font.family: Theme.fonts.sans
                    font.pixelSize: 14
                    background: Item {}
                    width: parent.width - 16 - 9
                    anchors.verticalCenter: parent.verticalCenter
                    selectByMouse: true
                }
            }
        }

        Item {
            width: parent.width
            height: Math.max(inboxLabel.implicitHeight, sortRow.implicitHeight)

            Text {
                id: inboxLabel
                text: "Inbox"
                color: Theme.text
                font.family: Theme.fonts.sans
                font.pixelSize: 19
                font.weight: Font.Bold
                font.letterSpacing: -0.2
            }
            Row {
                id: sortRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5
                Text {
                    text: "Newest"
                    color: Theme.textDim
                    font.family: Theme.fonts.sans
                    font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                }
                Icon {
                    name: "chevron-down"; size: 14; color: Theme.textDim
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // hairline divider under the header
    Rectangle {
        anchors.top: top.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.hairline
    }

    ListView {
        id: list
        clip: true
        anchors.top: top.bottom
        anchors.topMargin: 13
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.bottomMargin: 6
        spacing: 0
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            opacity: 0.4
        }

        model: root.model_
        delegate: MessageRow {
            width: list.width
            msg: modelData
            active: root.currentIndex === index
            onClicked: root.rowClicked(index)
        }

        FastWheel { flickable: list }
    }

    // empty-state placeholder
    Text {
        visible: list.count === 0
        anchors.centerIn: list
        text: "No messages"
        color: Theme.textFaint
        font.family: Theme.fonts.sans
        font.pixelSize: 13
    }
}
