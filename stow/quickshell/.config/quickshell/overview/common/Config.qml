pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root
    
    property QtObject options: QtObject {
        property QtObject overview: QtObject {
            // Filas y columnas: salen del reparto de escritorios por monitor (HyprlandData.workspaceRows)
            property real scale: 0.16
            property bool enable: true
        }
        
        property QtObject hacks: QtObject {
            property int arbitraryRaceConditionDelay: 150
        }
    }
}
