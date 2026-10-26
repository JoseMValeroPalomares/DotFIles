import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createPoll } from "ags/time"

export default function CalendarPanel(gdkmonitor: Gdk.Monitor) {
  const time = createPoll("", 1000, "date '+%H:%M'")
  const fullDate = createPoll("", 60000, "date '+%A, %d de %B'")
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={false}
      name="calendar-panel"
      class="CalendarPanel"
      gdkmonitor={gdkmonitor}
      anchor={TOP | RIGHT}
      application={app}
    >
      <box orientation={Gtk.Orientation.VERTICAL} cssName="calendar-container">
        <box orientation={Gtk.Orientation.VERTICAL} cssName="calendar-header">
            <label class="big-clock" label={time} halign={Gtk.Align.START} />
            <label class="date-label" label={fullDate} halign={Gtk.Align.START} />
        </box>
        <Gtk.Calendar cssName="custom-calendar" />
      </box>
    </window>
  )
}