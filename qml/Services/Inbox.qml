pragma Singleton

import QtQuick
import Bounce.Mail 1.0

// Thin facade over the C++ GmailService. Keeps QML call-sites stable if
// we add other folders / providers later.
QtObject {
    readonly property var messages:       GmailService.messages
    readonly property bool loading:       GmailService.loading
    readonly property string error:       GmailService.error
    readonly property var currentThread:  GmailService.currentThread
    readonly property bool threadLoading: GmailService.threadLoading

    function refresh() { GmailService.fetchInbox(); }
    function openThread(id) { GmailService.fetchThread(id); }
    function closeThread()  { GmailService.clearThread(); }
}
