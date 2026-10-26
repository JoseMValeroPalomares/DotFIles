pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Provides access to some Hyprland data not available in Quickshell.Hyprland.
 */
Singleton {
    id: root
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var workspaceIds: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property var layers: ({})

    function updateWindowList() {
        getClients.running = true;
    }

    function updateLayers() {
        getLayers.running = true;
    }

    function updateMonitors() {
        getMonitors.running = true;
    }

    function updateWorkspaces() {
        getWorkspaces.running = true;
        getActiveWorkspace.running = true;
    }

    function updateAll() {
        updateWindowList();
        updateMonitors();
        updateLayers();
        updateWorkspaces();
    }

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = HyprlandData.windowList.filter(w => w.workspace.id == workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    // Escritorios de cada monitor según las reglas de Hyprland (workspaces.lua)
    property var workspaceRules: []

    // Filas del overview: primero los escritorios del monitor indicado, luego los de los demás (por posición x).
    // Sin reglas: 1-5 arriba y 6-10 abajo.
    function workspaceRows(monitorName) {
        const byMonitor = {};
        for (const rule of root.workspaceRules) {
            const id = parseInt(rule.workspaceString);
            if (!rule.monitor || isNaN(id) || String(id) !== rule.workspaceString) continue;
            (byMonitor[rule.monitor] = byMonitor[rule.monitor] ?? []).push(id);
        }
        const names = Object.keys(byMonitor);
        if (names.length === 0) return [[1, 2, 3, 4, 5], [6, 7, 8, 9, 10]];
        const xOf = name => root.monitors.find(m => m.name === name)?.x ?? 0;
        names.sort((a, b) => (a === monitorName ? -1 : b === monitorName ? 1 : xOf(a) - xOf(b)));
        return names.map(name => byMonitor[name].sort((a, b) => a - b));
    }

    function updateWorkspaceRules() {
        getWorkspaceRules.running = true;
    }

    Component.onCompleted: {
        updateAll();
        updateWorkspaceRules();
    }

    // Solo se consulta a Hyprland con el overview abierto (antes: 5 hyprctl por cada evento, aunque estuviera oculto)
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "configreloaded")
                root.updateWorkspaceRules();
            if (GlobalStates.overviewOpen)
                refreshTimer.restart();
        }
    }

    Connections {
        target: GlobalStates

        function onOverviewOpenChanged() {
            if (GlobalStates.overviewOpen)
                root.updateAll();
        }
    }

    // Agrupa ráfagas de eventos en una sola actualización
    Timer {
        id: refreshTimer
        interval: 30
        onTriggered: root.updateAll()
    }

    Process {
        id: getWorkspaceRules
        command: ["hyprctl", "workspacerules", "-j"]
        stdout: StdioCollector {
            id: workspaceRulesCollector
            onStreamFinished: {
                root.workspaceRules = JSON.parse(workspaceRulesCollector.text);
            }
        }
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                root.windowList = JSON.parse(clientsCollector.text)
                let tempWinByAddress = {};
                for (var i = 0; i < root.windowList.length; ++i) {
                    var win = root.windowList[i];
                    tempWinByAddress[win.address] = win;
                }
                root.windowByAddress = tempWinByAddress;
                root.addresses = root.windowList.map(win => win.address);
            }
        }
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                root.monitors = JSON.parse(monitorsCollector.text);
            }
        }
    }

    Process {
        id: getLayers
        command: ["hyprctl", "layers", "-j"]
        stdout: StdioCollector {
            id: layersCollector
            onStreamFinished: {
                root.layers = JSON.parse(layersCollector.text);
            }
        }
    }

    Process {
        id: getWorkspaces
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            id: workspacesCollector
            onStreamFinished: {
                root.workspaces = JSON.parse(workspacesCollector.text);
                let tempWorkspaceById = {};
                for (var i = 0; i < root.workspaces.length; ++i) {
                    var ws = root.workspaces[i];
                    tempWorkspaceById[ws.id] = ws;
                }
                root.workspaceById = tempWorkspaceById;
                root.workspaceIds = root.workspaces.map(ws => ws.id);
            }
        }
    }

    Process {
        id: getActiveWorkspace
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            id: activeWorkspaceCollector
            onStreamFinished: {
                root.activeWorkspace = JSON.parse(activeWorkspaceCollector.text);
            }
        }
    }
}
