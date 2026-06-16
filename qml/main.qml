import QtQuick
import QtQuick.Window
import Theme 1.0
import Auth 1.0
import Mail 1.0
import Services 1.0

Window {
    id: root
    width: 1280
    height: 820
    minimumWidth: 980
    minimumHeight: 640
    visible: true
    title: qsTr("bounce — Mail")
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint

    // Auth-gated root. Three states — restoring (keychain read + refresh
    // in flight), signed in, or not. Loader keeps it simple; if we add
    // deeper navigation later, switch to StackView.
    Loader {
        anchors.fill: parent
        sourceComponent: Session.restoring ? loadingComp
                       : Session.signedIn ? mailComp
                       : authComp

        Component { id: loadingComp; LoadingScreen {} }
        Component { id: authComp;    AuthScreen {} }
        Component { id: mailComp;    MailWindow {} }
    }
}
