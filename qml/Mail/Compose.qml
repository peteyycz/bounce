import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Theme 1.0

// Floating bottom-right compose window. Toggled via `shown`.
Rectangle {
    id: root
    property bool shown: false
    signal closed()

    width: 540
    height: 480
    radius: Theme.rLg
    color: Theme.bgSolid
    border.color: Theme.border
    border.width: 1
    visible: opacity > 0.01

    opacity: 0
    transform: [
        Translate { id: tr; y: 12 },
        Scale { id: sc; origin.x: root.width / 2; origin.y: root.height; xScale: 0.98; yScale: 0.98 }
    ]
    states: State {
        name: "shown"; when: root.shown
        PropertyChanges { target: root; opacity: 1 }
        PropertyChanges { target: tr; y: 0 }
        PropertyChanges { target: sc; xScale: 1; yScale: 1 }
    }
    transitions: Transition {
        NumberAnimation { properties: "opacity,y,xScale,yScale"; duration: 280
            easing.type: Easing.OutCubic }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // header
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 44

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "New Message"
                color: Theme.text
                font.family: Theme.fonts.sans
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                IconButton { icon: "minus";      iconSize: 15; width: 26; height: 26; radius: 6 }
                IconButton { icon: "maximize-2"; iconSize: 15; width: 26; height: 26; radius: 6 }
                IconButton { icon: "x";          iconSize: 15; width: 26; height: 26; radius: 6; onClicked: root.closed() }
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }

        // To
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 10
                Text {
                    text: "To"
                    color: Theme.textFaint
                    font.family: Theme.fonts.sans
                    font.pixelSize: 14
                    Layout.preferredWidth: 42
                    Layout.alignment: Qt.AlignVCenter
                }
                TextField {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    placeholderText: "Recipients"
                    placeholderTextColor: Theme.textFaint
                    color: Theme.text
                    font.family: Theme.fonts.sans
                    font.pixelSize: 14
                    background: Item {}
                    selectByMouse: true
                }
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }

        // Subject
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 10
                Text {
                    text: "Subject"
                    color: Theme.textFaint
                    font.family: Theme.fonts.sans
                    font.pixelSize: 14
                    Layout.preferredWidth: 42
                    Layout.alignment: Qt.AlignVCenter
                }
                TextField {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    placeholderText: "Subject"
                    placeholderTextColor: Theme.textFaint
                    color: Theme.text
                    font.family: Theme.fonts.sans
                    font.pixelSize: 14
                    background: Item {}
                    selectByMouse: true
                }
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }

        // body
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            TextArea {
                anchors.fill: parent
                anchors.margins: 16
                placeholderText: "Type your message…"
                placeholderTextColor: Theme.textFaint
                color: Theme.text
                font.family: Theme.fonts.sans
                font.pixelSize: 14
                wrapMode: TextArea.Wrap
                background: Item {}
                selectByMouse: true
            }
        }

        // foot
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 8

                Rectangle {
                    Layout.preferredHeight: 36
                    Layout.preferredWidth: sendRow.implicitWidth + 36
                    Layout.alignment: Qt.AlignVCenter
                    radius: Theme.rMd
                    color: Theme.accent
                    Row {
                        id: sendRow
                        anchors.centerIn: parent
                        spacing: 8
                        Icon { name: "send"; size: 15; color: Theme.accentInk; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: "Send"
                            color: Theme.accentInk
                            font.family: Theme.fonts.sans
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Row {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 6
                    spacing: 2
                    IconButton { icon: "paperclip"; iconSize: 16; width: 32; height: 32 }
                    IconButton { icon: "image";     iconSize: 16; width: 32; height: 32 }
                    IconButton { icon: "smile";     iconSize: 16; width: 32; height: 32 }
                    IconButton { icon: "link";      iconSize: 16; width: 32; height: 32 }
                }

                Item { Layout.fillWidth: true; Layout.preferredHeight: 1 }

                IconButton {
                    icon: "trash-2"; iconSize: 16
                    width: 32; height: 32
                    baseColor: Theme.textFaint
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}
