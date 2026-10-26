#!/usr/bin/env bash
# Batería de notificaciones de prueba para swaync
img="$HOME/.config/swaync/images"
ico="$HOME/.config/swaync/icons"

notify-send -u low -a "Sistema" -i "$img/ja.png" "Prioridad baja" "Aviso discreto que desaparece pronto."
sleep 0.4
notify-send -u normal -a "Correo" -i mail-unread "Nuevo mensaje de Ana" "¿Quedamos mañana a las 10 para revisar el proyecto? Te paso el enlace del documento."
sleep 0.4
notify-send -u critical -a "Batería" -i "$ico/battery-status.png" "Batería al 5 %" "Conecta el cargador ahora."
sleep 0.4
notify-send -e -u low -a "Volumen" -h string:x-canonical-private-synchronous:volume_notif -h int:value:65 -i "$ico/volume-high.png" "Volumen" "65 %"
sleep 0.4
notify-send -a "Descargas" -i folder-download -A open=Abrir -A dismiss=Descartar "Descarga completada" "archivo-con-un-nombre-muy-largo-que-deberia-cortarse-bien-sin-romper-el-diseno.tar.zst" &
sleep 0.4
notify-send -a "Galería" -i "$img/note.png" -h "string:image-path:$img/bell.png" "Captura guardada" "Se ha guardado en ~/Imágenes/Capturas."
sleep 0.4
for i in 1 2 3; do notify-send -a "Discord" -i discord "Mensaje $i" "Texto de ejemplo número $i"; done
