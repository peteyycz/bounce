import QtQuick
import QtQuick.Shapes
import Common 1.0
import Theme 1.0
import Services 1.0

// Shown while we don't yet know if the user has a stored session.
Item {
    id: root

    GlassSurface {
        anchors.centerIn: parent
        width: 280
        height: 180
        shown: true

        Column {
            anchors.centerIn: parent
            spacing: 18

            Item {
                id: spinner
                anchors.horizontalCenter: parent.horizontalCenter
                width: 32; height: 32

                readonly property int thickness: 3

                // background ring
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
                            startAngle: -90
                            sweepAngle: 360
                        }
                    }
                }

                // rotating accent wedge
                Shape {
                    anchors.fill: parent
                    antialiasing: true
                    RotationAnimation on rotation {
                        from: 0; to: 360
                        duration: 900
                        loops: Animation.Infinite
                        running: root.visible
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
                            startAngle: -90
                            sweepAngle: 110
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Session.status || "Loading…"
                color: Theme.textDim
                font.family: Theme.fonts.sans
                font.pixelSize: 13
            }
        }
    }
}
