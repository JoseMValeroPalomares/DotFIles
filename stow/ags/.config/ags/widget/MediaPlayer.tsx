import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { execAsync } from "ags/process"

export default function MediaPlayer(gdkmonitor: Gdk.Monitor) {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      name="mediaplayer"
      visible={false}
      cssName="MediaPanel"
      gdkmonitor={gdkmonitor}
      anchor={TOP | RIGHT}
      application={app}
      margin={10}
    >
      <box orientation={Gtk.Orientation.VERTICAL} cssName="panel-container" spacing={10}>
        <label label="Reproductor" cssName="media-title" />
        
        <box spacing={15}>
            <image iconName="audio-x-generic-symbolic" pixelSize={64} />
            <box orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.START} valign={Gtk.Align.CENTER}>
                <label cssName="song-title" label="Música" />
                <label cssName="song-artist" label="Sistema" />
            </box>
        </box>

        <box halign={Gtk.Align.CENTER} spacing={20} cssName="controls">
            <button onClicked={() => execAsync("playerctl previous")}>
                <image iconName="media-skip-backward-symbolic" />
            </button>
            <button cssName="play-pause-btn" onClicked={() => execAsync("playerctl play-pause")}>
                <image iconName="media-playback-start-symbolic" />
            </button>
            <button onClicked={() => execAsync("playerctl next")}>
                <image iconName="media-skip-forward-symbolic" />
            </button>
        </box>
      </box>
    </window>
  )
}