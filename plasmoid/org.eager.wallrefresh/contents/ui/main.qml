import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property string imagePath: ""
    property string wallTitle: "No wallpaper info yet"
    property bool busy: false
    property string provider: "default"

    readonly property string readCmd: "cat \"$HOME/.cache/wallrefresh/current.txt\""

    Plasmoid.icon: "preferences-desktop-wallpaper"
    toolTipMainText: "Wallpaper"
    toolTipSubText: wallTitle

    function readState() { exec.connectSource(readCmd) }

    function refresh() {
        if (busy) return
        busy = true
        var arg = provider === "default" ? "" : " " + provider
        exec.connectSource("$HOME/.local/bin/wallrefresh" + arg)
    }

    onExpandedChanged: if (expanded) readState()
    Component.onCompleted: readState()

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            if (sourceName === root.readCmd) {
                var lines = (data["stdout"] || "").split("\n")
                if (lines[0]) {
                    root.imagePath = lines[0]
                    root.wallTitle = lines[1] || ""
                }
            } else {
                root.busy = false
                if (data["exit code"] !== 0) {
                    root.wallTitle = "Refresh failed: " + (data["stderr"] || "").trim().split("\n").pop()
                } else {
                    root.readState()
                }
            }
        }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Refresh wallpaper now"
            icon.name: "view-refresh"
            onTriggered: root.refresh()
        }
    ]

    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        Layout.preferredHeight: Kirigami.Units.gridUnit * 17
        spacing: Kirigami.Units.smallSpacing

        Image {
            Layout.fillWidth: true
            Layout.fillHeight: true
            source: root.imagePath ? "file://" + root.imagePath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            sourceSize.width: 900

            QQC2.BusyIndicator {
                anchors.centerIn: parent
                running: root.busy
                visible: root.busy
            }
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: root.wallTitle
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            QQC2.ComboBox {
                model: ["default", "unsplash", "wallhaven", "pixabay", "random"]
                onActivated: root.provider = currentText
            }
            Item { Layout.fillWidth: true }
            QQC2.Button {
                text: root.busy ? "Fetching…" : "Refresh"
                icon.name: "view-refresh"
                enabled: !root.busy
                onClicked: root.refresh()
            }
        }
    }
}
