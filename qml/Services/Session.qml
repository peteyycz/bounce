pragma Singleton

import QtQuick
import Bounce.Auth 1.0

// Thin facade over the C++ GoogleAuth singleton. Keeps the call-sites in
// QML stable if we add other providers later.
QtObject {
    readonly property bool signedIn:   GoogleAuth.authenticated
    readonly property bool restoring:  GoogleAuth.restoring
    readonly property string userName:  GoogleAuth.userName
    readonly property string userEmail: GoogleAuth.userEmail
    readonly property string status:    GoogleAuth.status
    readonly property bool configured:  GoogleAuth.configured

    function signIn()  { GoogleAuth.signIn(); }
    function signOut() { GoogleAuth.signOut(); }
}
