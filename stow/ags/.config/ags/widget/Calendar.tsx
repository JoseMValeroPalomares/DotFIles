import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"

export default function CalendarWidget() {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      name="calendar"
      application={app}
      anchor={TOP | RIGHT}
      margin={10}
    >
      <box cssName="calendar-container">
        <Gtk.Calendar />
      </box>
    </window>
  )
}