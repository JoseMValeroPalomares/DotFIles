pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root
    property bool overviewOpen: false
    property string overviewMonitor: "" // monitor donde se abrió (solo se muestra ahí)
    property bool superReleaseMightTrigger: true
}
