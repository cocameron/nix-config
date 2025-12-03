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
                    color: sessionMouseArea.containsMouse ? "#45475a" : "#313244"
                    radius: 15
                    border.color: sessionMouseArea.containsMouse ? "#89b4fa" : "#45475a"
                    border.width: sessionMouseArea.containsMouse ? 3 : 2

                    // Smooth transition for hover effect
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }
                    Behavior on border.width {
                        NumberAnimation { duration: 150 }
                    }

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
                                color: sessionMouseArea.containsMouse ? "#585b70" : "#45475a"
                                radius: 10

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
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
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            sessionGrid.currentIndex = index
                            selectedSessionIndex = index
                            // Auto-login with empty password
                            sddm.login(userName, "", index)
                        }
                    }
                }
            }

            // Keyboard navigation
            Keys.onLeftPressed: moveCurrentIndexLeft()
            Keys.onRightPressed: moveCurrentIndexRight()
            Keys.onUpPressed: moveCurrentIndexUp()
            Keys.onDownPressed: moveCurrentIndexDown()
            Keys.onReturnPressed: {
                selectedSessionIndex = currentIndex
                // Auto-login with empty password
                sddm.login(userName, "", currentIndex)
            }
        }

        // Instructions
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Use arrow keys or controller to navigate • Enter or click to login"
            font.pixelSize: 16
            color: "#6c7086"
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
    }
}
