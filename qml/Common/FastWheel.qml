import QtQuick

// Drop inside a Flickable/ListView/ScrollView to replace its default
// wheel scrolling with a Chromium-feel step. Flickable's built-in wheel
// step is ~20px/notch; this maps angleDelta directly so a notch moves
// ~120px, matching what QtWebEngine does inside its own pages.
WheelHandler {
    id: root
    required property Flickable flickable
    property real pixelsPerDeg: 1.0

    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

    onWheel: function(ev) {
        const f = root.flickable;
        if (!f) return;
        const maxY = Math.max(0, f.contentHeight - f.height);
        f.contentY = Math.max(0, Math.min(maxY, f.contentY - ev.angleDelta.y * root.pixelsPerDeg));
        ev.accepted = true;
    }
}
