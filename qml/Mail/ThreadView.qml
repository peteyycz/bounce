import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import Common 1.0
import Theme 1.0

// One thread opened in place of the message list. `msg` is the list row
// data (used until the fetch completes so we have something to render);
// `thread` is the loaded message array; `loading` is the request state.
Item {
    id: root
    property var msg
    property var thread: []
    property bool loading: false

    signal back()

    // ---- toolbar ----------------------------------------------------------
    Item {
        id: tbar
        width: parent.width
        height: 56
        anchors.top: parent.top

        IconButton {
            icon: "arrow-left"
            iconSize: 18
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.back()
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 56
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: root.msg ? root.msg.subject : ""
            color: Theme.text
            font.family: Theme.fonts.sans
            font.pixelSize: 14
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }
    Rectangle {
        anchors.top: tbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.hairline
    }

    // ---- body -------------------------------------------------------------
    ScrollView {
        id: scroll
        anchors.top: tbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 1
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Item {
            implicitWidth: scroll.width
            implicitHeight: col.implicitHeight + 60

            FastWheel { flickable: scroll.contentItem }

            Column {
                id: col
                x: 32; y: 26
                width: Math.min(parent.width - 64, 760)
                spacing: 14

                // big subject + chips
                Text {
                    text: root.msg ? root.msg.subject : ""
                    color: Theme.text
                    font.family: Theme.fonts.sans
                    font.pixelSize: 25
                    font.weight: Font.Bold
                    font.letterSpacing: -0.25
                    lineHeight: 1.25
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
                Row {
                    spacing: 7
                    visible: root.msg && root.msg.chips && root.msg.chips.length > 0
                    Repeater {
                        model: root.msg ? root.msg.chips : []
                        delegate: Chip { kind: modelData.kind; label: modelData.label }
                    }
                }

                // loading state — only when no messages yet
                Row {
                    visible: root.loading && (!root.thread || root.thread.length === 0)
                    spacing: 12

                    Item {
                        id: spinner
                        width: 18; height: 18
                        readonly property int thickness: 2

                        Shape {
                            anchors.fill: parent
                            antialiasing: true
                            ShapePath {
                                strokeWidth: spinner.thickness
                                strokeColor: Theme.fillStrong
                                fillColor: "transparent"
                                startX: spinner.width / 2
                                startY: spinner.thickness / 2
                                PathAngleArc {
                                    centerX: spinner.width / 2
                                    centerY: spinner.height / 2
                                    radiusX: (spinner.width - spinner.thickness) / 2
                                    radiusY: (spinner.height - spinner.thickness) / 2
                                    startAngle: -90; sweepAngle: 360
                                }
                            }
                        }
                        Shape {
                            anchors.fill: parent
                            antialiasing: true
                            RotationAnimation on rotation {
                                from: 0; to: 360
                                duration: 900
                                loops: Animation.Infinite
                                running: spinner.visible
                            }
                            ShapePath {
                                strokeWidth: spinner.thickness
                                strokeColor: Theme.accent
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                startX: spinner.width / 2
                                startY: spinner.thickness / 2
                                PathAngleArc {
                                    centerX: spinner.width / 2
                                    centerY: spinner.height / 2
                                    radiusX: (spinner.width - spinner.thickness) / 2
                                    radiusY: (spinner.height - spinner.thickness) / 2
                                    startAngle: -90; sweepAngle: 110
                                }
                            }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Loading thread…"
                        color: Theme.textDim
                        font.family: Theme.fonts.sans
                        font.pixelSize: 13
                    }
                }

                // the actual thread
                Column {
                    width: parent.width
                    spacing: 14
                    Repeater {
                        model: root.thread || []
                        delegate: ThreadMessage {
                            msg: modelData
                            width: parent ? parent.width : 0
                            onWheelDelta: function(dy) {
                                const f = scroll.contentItem;
                                const maxY = Math.max(0, f.contentHeight - f.height);
                                f.contentY = Math.max(0, Math.min(maxY, f.contentY - dy));
                            }
                        }
                    }
                }
            }
        }
    }
}
