import QtQuick
import Theme 1.0

// Rounded glass panel. Pops in with a scale-from-top-right + fade when
// `shown` becomes true. Children placed as default content render directly
// inside the rounded rectangle; clip them in their own components when
// needed (e.g. ListView already clips).
Rectangle {
    id: root

    property bool shown: true
    default property alias content: container.data

    radius: Theme.rLg
    color: Theme.bg
    antialiasing: true

    opacity: 0
    transform: Scale {
        id: popScale
        origin.x: root.width
        origin.y: 0
        xScale: 0.97
        yScale: 0.97
    }
    states: State {
        name: "shown"
        when: root.shown
        PropertyChanges {
            target: root
            opacity: 1
        }
        PropertyChanges {
            target: popScale
            xScale: 1
            yScale: 1
        }
    }
    transitions: Transition {
        NumberAnimation {
            properties: "opacity,xScale,yScale"
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: container
        anchors.fill: parent
    }
}
