import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../common"
import "../../services"
import "."

Scope {
    id: overviewScope
    Variants {
        id: overviewVariants
        model: Quickshell.screens
        PanelWindow {
            id: root
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)
            screen: modelData
            // Solo en el monitor donde se abrió
            visible: GlobalStates.overviewOpen && monitor?.name === GlobalStates.overviewMonitor

            WlrLayershell.namespace: "quickshell:overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            mask: Region {
                item: GlobalStates.overviewOpen ? keyHandler : null
            }

            anchors {
                top: true
                bottom: true
                left: !(Config?.options.overview.enable ?? true) 
                right: !(Config?.options.overview.enable ?? true) 
            }

            HyprlandFocusGrab {
                id: grab
                windows: [root]
                property bool canBeActive: root.monitorIsFocused
                active: false
                onCleared: () => {
                    if (!active)
                        GlobalStates.overviewOpen = false;
                }
            }

            Connections {
                target: GlobalStates
                function onOverviewOpenChanged() {
                    if (GlobalStates.overviewOpen) {
                        delayedGrabTimer.start();
                    }
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: Config.options.hacks.arbitraryRaceConditionDelay
                repeat: false
                onTriggered: {
                    if (!grab.canBeActive)
                        return;
                    grab.active = GlobalStates.overviewOpen;
                }
            }

            implicitWidth: columnLayout.implicitWidth
            implicitHeight: columnLayout.implicitHeight

            Item {
                id: keyHandler
                anchors.fill: parent
                visible: GlobalStates.overviewOpen
                focus: GlobalStates.overviewOpen

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape || event.key === Qt.Key_Return) {
                        GlobalStates.overviewOpen = false;
                        event.accepted = true;
                    } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                        // 1-9 y 0 (= 10): ir a ese escritorio y cerrar
                        const target = event.key === Qt.Key_0 ? 10 : event.key - Qt.Key_0;
                        GlobalStates.overviewOpen = false;
                        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${target} })`);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right || event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                        // Moverse por la cuadrícula: una fila por monitor
                        const rows = HyprlandData.workspaceRows(GlobalStates.overviewMonitor);
                        const currentId = Hyprland.focusedMonitor?.activeWorkspace?.id ?? rows[0][0];
                        let r = Math.max(rows.findIndex(row => row.includes(currentId)), 0);
                        let c = Math.max(rows[r].indexOf(currentId), 0);

                        if (event.key === Qt.Key_Left) {
                            c = (c - 1 + rows[r].length) % rows[r].length;
                        } else if (event.key === Qt.Key_Right) {
                            c = (c + 1) % rows[r].length;
                        } else {
                            r = (r + (event.key === Qt.Key_Up ? -1 : 1) + rows.length) % rows.length;
                            c = Math.min(c, rows[r].length - 1);
                        }

                        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${rows[r][c]} })`);
                        event.accepted = true;
                    }
                }
            }

            ColumnLayout {
                id: columnLayout
                visible: GlobalStates.overviewOpen
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: 100
                }

                Loader {
                    id: overviewLoader
                    active: GlobalStates.overviewOpen && (Config?.options.overview.enable ?? true)
                    sourceComponent: OverviewWidget {
                        panelWindow: root
                        visible: true
                    }
                }
            }
        }
    }
    
    IpcHandler {
        target: "overview"

        function toggle() {
            if (!GlobalStates.overviewOpen)
                GlobalStates.overviewMonitor = Hyprland.focusedMonitor?.name ?? "";
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function close() {
            GlobalStates.overviewOpen = false;
        }
        function open() {
            GlobalStates.overviewMonitor = Hyprland.focusedMonitor?.name ?? "";
            GlobalStates.overviewOpen = true;
        }
    }
}
