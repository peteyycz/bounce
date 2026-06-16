import QtQuick
import QtQuick.Layouts
import Theme 1.0
import Services 1.0

// Left pane: traffic lights, account, compose button, nav.
Item {
    id: root
    property int activeIndex: 0
    signal composeClicked()
    signal navClicked(int index)

    implicitWidth: 248

    // account header
    Row {
        id: acct
        x: 20; y: 18
        width: parent.width - 40
        spacing: 11

        Avatar {
            paletteIndex: -1; size: 38; fontSize: 15
            initials: ""
            anchors.verticalCenter: parent.verticalCenter
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 38 - 16 - 11 * 2
            spacing: 1
            Text {
                text: Session.userName || "Not signed in"
                color: Session.signedIn ? Theme.text : Theme.textDim
                font.family: Theme.fonts.sans
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                text: Session.userEmail
                color: Theme.textDim
                font.family: Theme.fonts.sans
                font.pixelSize: 12
                elide: Text.ElideRight
                width: parent.width
            }
        }
        Icon {
            name: "chevrons-up-down"
            size: 16
            color: Theme.textFaint
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // compose button
    Rectangle {
        id: composeBtn
        x: 18
        anchors.top: acct.bottom
        anchors.topMargin: 14
        width: parent.width - 36
        height: 40
        radius: Theme.rMd
        color: Theme.accent

        Row {
            anchors.centerIn: parent
            spacing: 9
            Icon { name: "pencil-line"; size: 17; color: Theme.accentInk; anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: "Compose"
                color: Theme.accentInk
                font.family: Theme.fonts.sans
                font.pixelSize: 14
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.composeClicked()
            onPressed: composeBtn.scale = 0.985
            onReleased: composeBtn.scale = 1
        }
        Behavior on scale { NumberAnimation { duration: 100 } }
    }

    // nav
    Column {
        id: nav
        x: 18
        anchors.top: composeBtn.bottom
        anchors.topMargin: 10
        width: parent.width - 36
        spacing: 2

        Repeater {
            model: [
                { icon: "inbox",        label: "Inbox"   },
                { icon: "star",         label: "Starred" },
                { icon: "send",         label: "Sent"    },
                { icon: "file-text",    label: "Drafts"  },
                { icon: "archive",      label: "Archive" },
                { icon: "shield-alert", label: "Spam"    },
                { icon: "trash-2",      label: "Trash"   }
            ]
            delegate: NavItem {
                width: nav.width
                icon: modelData.icon
                label: modelData.label
                count: ""
                active: root.activeIndex === index
                onClicked: root.navClicked(index)
            }
        }

        Text {
            text: "LABELS"
            color: Theme.textFaint
            font.family: Theme.fonts.sans
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 0.6
            topPadding: 14
            bottomPadding: 6
            leftPadding: 10
        }

        // Labels list populated from user data later.
        Repeater {
            model: []
            delegate: NavItem {
                width: nav.width
                dot: modelData.dot
                label: modelData.label
                count: ""
            }
        }
    }
}
