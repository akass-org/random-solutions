#!/bin/bash

KDED6="#!/bin/bash
exit 0"

KDED6_PATH="$HOME/.local/bin/kded6"

SH="#!/bin/bash
CURRENT_DESKTOP=\$XDG_CURRENT_DESKTOP

if [[ \$CURRENT_DESKTOP == \"KDE\" ]]; then
    if [[ -f  \"$KDED6_PATH\" ]]; then
        rm  \"$KDED6_PATH\"
    fi
else
    killall kded6
    echo \"$KDED6\" > \"$KDED6_PATH\"
    chmod +x \"$KDED6_PATH\"
fi
"

mkdir -p "$HOME/.config/niri/script/"
echo "$SH" > $HOME/.config/niri/script/mask_kded6.sh
chmod +x $HOME/.config/niri/script/mask_kded6.sh

AUTOSTART="[Desktop Entry]
Comment[zh_CN]=
Comment=
Exec=$HOME/.config/niri/script/mask_kded6.sh
GenericName[zh_CN]=
GenericName=
Icon=
MimeType=
Name[zh_CN]=mask_kded6
Name=mask_kded6
Path=
StartupNotify=true
Terminal=false
TerminalOptions=
Type=Application
X-KDE-SubstituteUID=false
X-KDE-Username="

echo "$AUTOSTART" > "$HOME/.config/autostart/mask_kded6.desktop"
