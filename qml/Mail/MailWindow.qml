import QtQuick
import QtQuick.Layouts
import Common 1.0
import Theme 1.0
import Services 1.0

// The three-pane mail UI sitting inside a single glass panel.
Item {
    id: root
    property int activeRow: -1

    GlassSurface {
        anchors.fill: parent
        shown: true

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Sidebar {
                id: sidebar
                Layout.preferredWidth: 248
                Layout.fillHeight: true
                onComposeClicked: compose.shown = true
            }

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.hairline }

            MessageList {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                model_: Inbox.messages
                currentIndex: root.activeRow
                onRowClicked: (index) => root.activeRow = index
            }
        }
    }

    Compose {
        id: compose
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 30
        anchors.bottomMargin: 22
        onClosed: shown = false
    }
}
