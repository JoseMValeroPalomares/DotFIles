import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { execAsync } from "ags/process"

export default function QuickSettings(gdkmonitor: Gdk.Monitor) {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={false}
      name="quicksettings"
      cssName="QuickSettings"
      gdkmonitor={gdkmonitor}
      anchor={TOP | RIGHT}
      application={app}
      margin={10} 
    >
      <box orientation={Gtk.Orientation.VERTICAL} cssName="panel-container">
        
        <box cssName="quick-toggles" spacing={10} homogeneous>
          <button onClicked={() => execAsync("nmcli radio wifi off")}>
            <box orientation={Gtk.Orientation.VERTICAL}>
              <image iconName="network-wireless-symbolic" />
              <label label="Wi-Fi" />
            </box>
          </button>
          <button onClicked={() => execAsync("rfkill toggle bluetooth")}>
            <box orientation={Gtk.Orientation.VERTICAL}>
              <image iconName="bluetooth-active-symbolic" />
              <label label="Bluetooth" />
            </box>
          </button>
        </box>

        <box orientation={Gtk.Orientation.VERTICAL} cssName="sliders-section" spacing={10}>
          <box spacing={10}>
            <image iconName="audio-volume-high-symbolic" />
            <slider 
                hexpand 
                // Cambiamos Gtk.Slider por Gtk.Scale
                onValueChanged={(self: Gtk.Scale) => {
                    const value = self.get_value();
                    execAsync(`wpctl set-volume @DEFAULT_AUDIO_SINK@ ${value.toFixed(2)}`);
                }}
            />
          </box>
        </box>

      </box>
    </window>
  )
}