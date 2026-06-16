import QtQuick
import QtQuick.Layouts
import Common 1.0
import Theme 1.0
import Services 1.0

// Unauthenticated state. Shown by main.qml when Session.signedIn is false.
Item {
    id: root

    GlassSurface {
        anchors.centerIn: parent
        width: 380
        height: 280
        shown: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 10

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "bounce"
                color: Theme.text
                font.family: Theme.fonts.sans
                font.pixelSize: 32
                font.weight: Font.Bold
                font.letterSpacing: -0.6
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Email, but quiet."
                color: Theme.textDim
                font.family: Theme.fonts.sans
                font.pixelSize: 14
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                id: signInBtn
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 240
                Layout.preferredHeight: 44
                radius: Theme.rMd
                color: Session.configured ? Theme.accent : Theme.fillStrong
                opacity: Session.configured ? 1.0 : 0.6

                Text {
                    anchors.centerIn: parent
                    text: "Sign in with Google"
                    color: Session.configured ? Theme.accentInk : Theme.textDim
                    font.family: Theme.fonts.sans
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: Session.configured
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Session.signIn()
                    onPressed: signInBtn.scale = 0.98
                    onReleased: signInBtn.scale = 1
                }
                Behavior on scale { NumberAnimation { duration: 100 } }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Session.status || "We'll open your browser to finish."
                color: Theme.textFaint
                font.family: Theme.fonts.sans
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }
    }
}
