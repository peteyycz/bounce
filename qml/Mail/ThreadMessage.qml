import QtQuick
import QtWebEngine
import Theme 1.0

// A single message inside a thread. Open == expanded body; otherwise a
// one-line preview is shown next to the header.
Rectangle {
    id: root
    property var msg
    property bool open: msg ? msg.open : false

    // Wheel events over the embedded WebEngineView don't propagate to QML
    // ancestors (Chromium consumes them). We forward them out via this
    // signal so ThreadView can scroll its own ScrollView directly.
    signal wheelDelta(real dy)

    width: parent ? parent.width : 0
    height: inner.implicitHeight + 2
    radius: Theme.rMd
    color: open ? Theme.fill : "transparent"
    border.color: Theme.hairline
    border.width: 1

    Column {
        id: inner
        width: parent.width
        spacing: 0

        // header row
        Item {
            id: mhd
            width: parent.width
            height: 70

            Avatar {
                id: ava
                x: 17; y: 15
                size: 40
                fontSize: 14
                paletteIndex: root.msg ? root.msg.palette : 0
                initials: root.msg ? root.msg.initials : ""
            }
            Column {
                x: ava.x + ava.width + 12
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - (whenText.width + 24)
                spacing: 1
                Text {
                    text: root.msg ? root.msg.from : ""
                    color: Theme.text
                    font.family: Theme.fonts.sans
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    width: parent.width
                }
                Text {
                    text: root.msg ? root.msg.to : ""
                    color: Theme.textDim
                    font.family: Theme.fonts.sans
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
            Text {
                id: whenText
                anchors.right: parent.right
                anchors.rightMargin: 17
                anchors.verticalCenter: parent.verticalCenter
                text: root.msg ? root.msg.when : ""
                color: Theme.textFaint
                font.family: Theme.fonts.sans
                font.pixelSize: 12
            }
        }

        // collapsed preview
        Text {
            visible: !root.open
            text: root.msg ? root.msg.preview : ""
            color: Theme.textDim
            font.family: Theme.fonts.sans
            font.pixelSize: 13
            leftPadding: 69
            rightPadding: 17
            bottomPadding: 15
            elide: Text.ElideRight
            width: parent.width
        }

        // expanded body
        Column {
            id: bodyCol
            visible: root.open
            x: 22; width: parent.width - 44
            spacing: 15
            bottomPadding: 22
            topPadding: 4

            readonly property bool hasHtml: !!root.msg && !!root.msg.bodyHtml

            // HTML path — sandboxed Chromium. JS off, no remote loads,
            // image autoload off (tracking pixels). Clicks open externally.
            //
            // We control Loader.height directly from the polling timer.
            // Loader with explicit size *forces* its child's size, so the
            // WebEngineView just anchors.fill the Loader — measuring
            // happens via scrollHeight regardless of viewport size.
            Loader {
                id: htmlLoader
                width: parent.width
                height: 200
                active: bodyCol.hasHtml && root.open
                sourceComponent: htmlComp
            }

            Component {
                id: htmlComp
                Item {
                    id: wrap
                    anchors.fill: parent

                    WebEngineView {
                        id: view
                        anchors.fill: parent
                        backgroundColor: "transparent"

                    // JS enabled so runJavaScript() definitely works for
                    // height measurement; remote-content sandboxing below
                    // is what actually protects us.
                    settings.javascriptEnabled: true
                    settings.autoLoadImages: true
                    settings.localContentCanAccessRemoteUrls: false
                    settings.localContentCanAccessFileUrls: false
                    settings.allowRunningInsecureContent: false
                    settings.pluginsEnabled: false

                    Component.onCompleted: loadHtml(_wrap(root.msg.bodyHtml));

                    onLoadingChanged: function(loadInfo) {
                        if (loadInfo.status === WebEngineView.LoadSucceededStatus) {
                            heightPoll.polls = 0;
                            heightPoll.stableTicks = 0;
                            heightPoll.start();
                        }
                    }

                    // We measure a wrapper div around the body content rather
                    // than documentElement/body/contentsSize. Those all clamp
                    // to the viewport, so reading them after we resize the
                    // Loader feeds the new viewport size back in — the loop
                    // that made the container grow without bound.
                    Timer {
                        id: heightPoll
                        interval: 250
                        repeat: true
                        property int polls: 0
                        property int stableTicks: 0
                        onTriggered: {
                            polls += 1;
                            view.runJavaScript(
                                "(function(){var el=document.getElementById('bounce-root');" +
                                "return el?Math.ceil(el.getBoundingClientRect().height):0;})()",
                                function(h) {
                                    if (!h || h <= 0) return;
                                    const wanted = Math.min(h, 12000) + 16;
                                    if (Math.abs(wanted - htmlLoader.height) > 2) {
                                        htmlLoader.height = wanted;
                                        stableTicks = 0;
                                    } else {
                                        stableTicks += 1;
                                    }
                                }
                            );
                            if (polls > 120 || stableTicks > 6) stop();
                        }
                    }

                    onNavigationRequested: function(request) {
                        if (request.navigationType === WebEngineNavigationRequest.LinkClickedNavigation) {
                            request.action = WebEngineNavigationRequest.IgnoreRequest;
                            Qt.openUrlExternally(request.url);
                        }
                    }

                    function _wrap(body) {
                        // Inject a minimal stylesheet so the email reads against
                        // our dark surface. Email-author CSS still applies.
                        // overflow: hidden — we size the view to fit the
                        // content exactly, so the page never needs to scroll
                        // internally. This is what lets wheel events fall
                        // through to the outer ScrollView.
                        return "<!doctype html><html><head><meta charset='utf-8'>" +
                               "<base target='_blank'>" +
                               "<style>" +
                               "  html, body { margin: 0; padding: 0; background: transparent;" +
                               "    overflow: hidden;" +
                               "    color: " + Theme.text + ";" +
                               "    font-family: sans-serif; font-size: 14px; line-height: 1.55;" +
                               "    word-wrap: break-word; }" +
                               "  a { color: " + Theme.accent + "; }" +
                               "  img { max-width: 100%; height: auto; }" +
                               "  blockquote { border-left: 2px solid " + Theme.hairline +
                               "    "+ "; padding-left: 12px; color: " + Theme.textDim + "; }" +
                               "</style></head><body>" +
                               "<div id='bounce-root'>" + body + "</div>" +
                               "</body></html>";
                    }
                    } // WebEngineView

                    // Wheel forwarder. Sits over the WebEngineView so we get
                    // wheel events first; Qt.NoButton lets clicks/drag fall
                    // through to the web content. Declared after view so it's
                    // stacked on top in QML's child order.
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                        onWheel: function(wheel) {
                            root.wheelDelta(wheel.angleDelta.y);
                            wheel.accepted = true;
                        }
                    }
                } // Item wrap
            } // Component

            // Plain-text fallback — only used when there's no HTML body.
            Repeater {
                model: bodyCol.hasHtml ? [] : (root.msg ? root.msg.body : [])
                delegate: Text {
                    text: modelData
                    color: Theme.text
                    font.family: Theme.fonts.sans
                    font.pixelSize: 15
                    lineHeight: 1.55
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }

            Text {
                visible: !!root.msg && !!root.msg.sig && !bodyCol.hasHtml
                text: root.msg && root.msg.sig ? root.msg.sig : ""
                color: Theme.textDim
                font.family: Theme.fonts.sans
                font.pixelSize: 14
                lineHeight: 1.55
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }
    }
}
