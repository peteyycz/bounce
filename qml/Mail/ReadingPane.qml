import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Common 1.0
import Theme 1.0

// Right pane: action toolbar + thread.
Item {
    id: root
    property var thread

    // action toolbar
    Item {
        id: tbar
        width: parent.width
        height: 60
        anchors.top: parent.top

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            IconButton { icon: "archive" }
            IconButton { icon: "trash-2" }
            IconButton { icon: "mail-open" }
            IconButton { icon: "clock" }
            IconButton { icon: "folder-input" }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                visible: !!root.thread
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                color: Theme.textFaint
                font.family: Theme.fonts.sans
                font.pixelSize: 13
                rightPadding: 8
            }
            IconButton { icon: "chevron-up" }
            IconButton { icon: "chevron-down" }
        }
    }

    // empty-state placeholder
    Text {
        visible: !root.thread
        anchors.centerIn: parent
        text: "No conversation selected"
        color: Theme.textFaint
        font.family: Theme.fonts.sans
        font.pixelSize: 14
    }

    Rectangle {
        anchors.top: tbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.hairline
    }

    ScrollView {
        id: scroll
        visible: !!root.thread
        anchors.top: tbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 1
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Item {
            implicitWidth: scroll.width
            implicitHeight: col.implicitHeight + 60

            FastWheel { flickable: scroll.contentItem }

            Column {
                id: col
                x: 32; y: 26
                width: Math.min(parent.width - 64, 760)
                spacing: 0

                Text {
                    text: root.thread ? root.thread.subject : ""
                    color: Theme.text
                    font.family: Theme.fonts.sans
                    font.pixelSize: 25
                    font.weight: Font.Bold
                    font.letterSpacing: -0.25
                    lineHeight: 1.25
                    wrapMode: Text.WordWrap
                    width: parent.width
                    bottomPadding: 6
                }

                Row {
                    spacing: 7
                    bottomPadding: 22
                    Repeater {
                        model: root.thread ? root.thread.chips : []
                        delegate: Chip { kind: modelData.kind; label: modelData.label }
                    }
                    Chip {
                        kind: ""
                        label: root.thread ? root.thread.countLabel : ""
                        overrideBg: Theme.fillStrong
                        overrideFg: Theme.textDim
                    }
                }

                Column {
                    spacing: 14
                    width: parent.width

                    Repeater {
                        model: root.thread ? root.thread.messages : []
                        delegate: ThreadMessage { msg: modelData; width: col.width }
                    }
                }

                // reply box
                Item { width: 1; height: 18 }

                Rectangle {
                    width: parent.width
                    height: 56
                    radius: Theme.rMd
                    color: "transparent"
                    border.color: Theme.hairline
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        Icon { name: "reply"; size: 18; color: Theme.textDim; Layout.alignment: Qt.AlignVCenter }
                        Text {
                            text: "Reply…"
                            color: Theme.textDim
                            font.family: Theme.fonts.sans
                            font.pixelSize: 14
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Item { Layout.fillWidth: true; Layout.preferredHeight: 1 }

                        Rectangle {
                            Layout.preferredHeight: 32
                            Layout.preferredWidth: replyAllRow.implicitWidth + 26
                            radius: Theme.rSm
                            color: Theme.fillStrong
                            Row {
                                id: replyAllRow
                                anchors.centerIn: parent
                                spacing: 6
                                Icon { name: "reply-all"; size: 14; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
                                Text {
                                    text: "Reply all"
                                    color: Theme.text
                                    font.family: Theme.fonts.sans
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                        Rectangle {
                            Layout.preferredHeight: 32
                            Layout.preferredWidth: replyOnlyRow.implicitWidth + 26
                            radius: Theme.rSm
                            color: Theme.accent
                            Row {
                                id: replyOnlyRow
                                anchors.centerIn: parent
                                spacing: 6
                                Icon { name: "reply"; size: 14; color: Theme.accentInk; anchors.verticalCenter: parent.verticalCenter }
                                Text {
                                    text: "Reply"
                                    color: Theme.accentInk
                                    font.family: Theme.fonts.sans
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
