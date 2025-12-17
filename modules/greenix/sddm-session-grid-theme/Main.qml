import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#1e1e2e"  // Dark background

    // Session selection state
    property int selectedSessionIndex: sessionModel.lastIndex
    property string userName: userModel.lastUser

    // Auto-select configuration
    property int autoSelectTimeout: 14000  // 14 seconds in milliseconds
    property string autoSelectSessionName: "gamescope"  // Session to auto-select
    property real autoSelectStartTime: 0

    // Find the gaming session index
    function findGamingSessionIndex() {
        console.log("Searching for gaming session among", sessionModel.rowCount(), "sessions")
        for (var i = 0; i < sessionModel.rowCount(); i++) {
            var sessionName = sessionModel.data(sessionModel.index(i, 0), 257).toLowerCase()  // Qt.DisplayRole = 257
            console.log("  Session", i + ":", sessionName)
            if (sessionName.includes("gamescope") || sessionName.includes("steam") || sessionName.includes("jovian")) {
                console.log("  -> Found gaming session at index", i)
                return i
            }
        }
        console.log("  -> Gaming session not found, defaulting to index 0")
        return 0  // Fallback to index 0 (where steamos gamescope should be)
    }

    // Auto-select timer
    Timer {
        id: autoSelectTimer
        interval: autoSelectTimeout
        running: true
        repeat: false
        onTriggered: {
            var gamingIndex = findGamingSessionIndex()
            console.log("Auto-selecting gaming session at index:", gamingIndex)
            sddm.login(userName, "", gamingIndex)
        }
        onRunningChanged: {
            if (running) {
                autoSelectStartTime = Date.now()
            }
        }
    }

    // Reset timer on any interaction
    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        onPressed: {
            autoSelectTimer.running = false
        }
        onPositionChanged: {
            autoSelectTimer.restart()
        }
    }

    // Main content
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 60
        width: parent.width * 0.8

        // Title
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Select Session"
            font.pixelSize: 48
            font.bold: true
            color: "#cdd6f4"
        }

        // User info
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "User: " + userName
            font.pixelSize: 24
            color: "#a6adc8"
        }

        // Session Grid
        GridView {
            id: sessionGrid
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(parent.width, cellWidth * 4)
            Layout.preferredHeight: Math.ceil(count / 4) * cellHeight

            cellWidth: 220
            cellHeight: 220

            model: sessionModel
            focus: true
            currentIndex: selectedSessionIndex

            // Highlight
            highlight: Rectangle {
                color: "#89b4fa"
                radius: 20
                border.color: "#cdd6f4"
                border.width: 3
            }
            highlightFollowsCurrentItem: true

            delegate: Item {
                width: sessionGrid.cellWidth
                height: sessionGrid.cellHeight

                Rectangle {
                    id: sessionItem
                    anchors.fill: parent
                    anchors.margins: 15
                    color: "#313244"
                    radius: 15
                    border.color: "#45475a"
                    border.width: 2

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 15

                        // Session Icon
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 96
                            Layout.preferredHeight: 96

                            // Icon background
                            Rectangle {
                                anchors.fill: parent
                                color: "#45475a"
                                radius: 10
                            }

                            // Nerd Font Icon
                            Text {
                                anchors.centerIn: parent
                                text: {
                                    var sessionName = (model.name || "").toLowerCase()
                                    if (sessionName.includes("plasma") || sessionName.includes("kde"))
                                        return ""  // nf-linux-kde
                                    else if (sessionName.includes("gnome"))
                                        return ""  // nf-linux-gnome
                                    else if (sessionName.includes("steam") || sessionName.includes("jovian"))
                                        return ""  // nf-fa-steam
                                    else if (sessionName.includes("niri"))
				    	return "niri"
				    else
                                        return "\uf17a"  // nf-fa-linux (generic)
                                }
                                font.family: "Symbols Nerd Font"
                                font.pixelSize: 64
                                color: "#cdd6f4"
                            }
                        }

                        // Session Name
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 180
                            text: model.name || "Unknown"
                            font.pixelSize: 18
                            color: "#cdd6f4"
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: sessionMouseArea
                        anchors.fill: parent
                        hoverEnabled: false
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            autoSelectTimer.stop()
                            sessionGrid.currentIndex = index
                            selectedSessionIndex = index
                            // Auto-login with empty password
                            sddm.login(userName, "", index)
                        }
                    }
                }
            }

            // Keyboard navigation
            Keys.onLeftPressed: {
                autoSelectTimer.restart()
                moveCurrentIndexLeft()
            }
            Keys.onRightPressed: {
                autoSelectTimer.restart()
                moveCurrentIndexRight()
            }
            Keys.onUpPressed: {
                autoSelectTimer.restart()
                moveCurrentIndexUp()
            }
            Keys.onDownPressed: {
                autoSelectTimer.restart()
                moveCurrentIndexDown()
            }
            Keys.onReturnPressed: {
                autoSelectTimer.stop()
                selectedSessionIndex = currentIndex
                // Auto-login with empty password
                sddm.login(userName, "", currentIndex)
            }
            Keys.onPressed: {
                // Reset timer on any key press
                autoSelectTimer.restart()
            }
        }

        // Instructions and countdown
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Use arrow keys or click to select • Press any key to cancel auto-select"
                font.pixelSize: 16
                color: "#6c7086"
            }

            Text {
                id: countdownText
                Layout.alignment: Qt.AlignHCenter
                text: "Auto-selecting gaming mode in " + Math.ceil(autoSelectTimer.interval / 1000) + "s..."
                font.pixelSize: 14
                color: "#89b4fa"
                visible: autoSelectTimer.running

                Timer {
                    interval: 100
                    running: autoSelectTimer.running
                    repeat: true
                    onTriggered: {
                        var remaining = autoSelectTimer.interval - (Date.now() - autoSelectStartTime)
                        if (remaining > 0) {
                            countdownText.text = "Auto-selecting gaming mode in " + Math.ceil(remaining / 1000) + "s..."
                        }
                    }
                }
            }
        }
    }

    // Power options in bottom right
    RowLayout {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 30
        spacing: 15

        // Reboot Button
        Rectangle {
            width: 100
            height: 40
            color: rebootMouseArea.pressed ? "#45475a" : "#313244"
            radius: 8

            Text {
                anchors.centerIn: parent
                text: "Reboot"
                font.pixelSize: 16
                color: "#f9e2af"
            }

            MouseArea {
                id: rebootMouseArea
                anchors.fill: parent
                onClicked: sddm.reboot()
            }
        }

        // Shutdown Button
        Rectangle {
            width: 100
            height: 40
            color: shutdownMouseArea.pressed ? "#45475a" : "#313244"
            radius: 8

            Text {
                anchors.centerIn: parent
                text: "Shutdown"
                font.pixelSize: 16
                color: "#f38ba8"
            }

            MouseArea {
                id: shutdownMouseArea
                anchors.fill: parent
                onClicked: sddm.powerOff()
            }
        }
    }

    Component.onCompleted: {
        sessionGrid.forceActiveFocus()
        autoSelectStartTime = Date.now()
    }
}
