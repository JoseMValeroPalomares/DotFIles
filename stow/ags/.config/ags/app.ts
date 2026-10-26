import app from "ags/gtk4/app"
import { Gdk } from "ags/gtk4"
import QuickSettings from "./widget/QuickSettings"
import CalendarPanel from "./widget/CalendarPanel"
import MediaPlayer from "./widget/MediaPlayer"

app.start({
  css: "./style.css",
  main() {
    const display = Gdk.Display.get_default()
    // Obtenemos el monitor principal. Usamos el casting 'as' para asegurar el tipo
    const monitors = display?.get_monitors()
    const monitor = monitors?.get_item(0) as Gdk.Monitor

    // Inicializamos las ventanas
    QuickSettings(monitor)
    CalendarPanel(monitor)
    MediaPlayer(monitor)
  },
})

// Corregido: 'request' es un array (string[]), tomamos el primer elemento
app.connect("request", (app, request, response) => {
    // Tomamos el primer argumento del comando (ej: 'quicksettings')
    const windowName = request[0] 
    
    const win = app.get_window(windowName)
    if (win) {
        win.visible = !win.visible
        response("ok")
    } else {
        response(`ventana '${windowName}' no encontrada`)
    }
})