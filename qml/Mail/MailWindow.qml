import QtQuick
import QtQuick.Layouts
import Common 1.0
import Theme 1.0
import Services 1.0

// Two-pane mail UI sitting inside a single glass panel. The right pane
// flips between the message list and a thread view when a row is opened.
Item {
    id: root
    property int activeRow: -1
    readonly property bool viewingThread: activeRow >= 0
                                       && activeRow < (Inbox.messages?.length ?? 0)

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

            // Loader swaps inbox <-> thread view in place.
            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: root.viewingThread ? threadComp : listComp

                Component {
                    id: listComp
                    MessageList {
                        model_: Inbox.messages
                        currentIndex: -1
                        onRowClicked: (index) => {
                            root.activeRow = index;
                            Inbox.openThread(Inbox.messages[index].threadId);
                        }
                    }
                }

                Component {
                    id: threadComp
                    ThreadView {
                        msg:    Inbox.messages[root.activeRow]
                        thread: Inbox.currentThread
                        loading: Inbox.threadLoading
                        onBack: {
                            root.activeRow = -1;
                            Inbox.closeThread();
                        }
                    }
                }
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
