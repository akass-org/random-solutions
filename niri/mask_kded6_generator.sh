#!/bin/bash

# PATH mask 假二进制
KDED6_FAKE="#!/bin/bash
exit 0"

# 路径定义
KDED6_PATH="$HOME/.local/bin/kded6"
DBUS_SERVICE_DIR="$HOME/.local/share/dbus-1/services"
DBUS_SERVICE_FILE="$DBUS_SERVICE_DIR/org.kde.kded6.service"

# 主脚本内容
SH="#!/bin/bash
CURRENT_DESKTOP=\$XDG_CURRENT_DESKTOP

if [[ \$CURRENT_DESKTOP == \"KDE\" ]]; then
    # 移除 PATH mask
    if [[ -f \"$KDED6_PATH\" ]]; then
        rm \"$KDED6_PATH\"
    fi
    
    # unmask systemd service
    systemctl --user unmask plasma-kded6.service 2>/dev/null
    
    # 移除 D-Bus service 覆盖
    if [[ -f \"$DBUS_SERVICE_FILE\" ]]; then
        rm \"$DBUS_SERVICE_FILE\"
    fi
else
    # 停止运行中的 kded6
    killall kded6 2>/dev/null
    
    # 创建 PATH mask
    mkdir -p \"\$(dirname \"$KDED6_PATH\")\"
    echo \"$KDED6_FAKE\" > \"$KDED6_PATH\"
    chmod +x \"$KDED6_PATH\"
    
    # mask systemd service
    systemctl --user mask plasma-kded6.service 2>/dev/null
    
    # 创建 D-Bus service 覆盖
    mkdir -p \"$DBUS_SERVICE_DIR\"
    cat > \"$DBUS_SERVICE_FILE\" << 'EOF'
[D-BUS Service]
Name=org.kde.kded6
Exec=/bin/false
EOF
fi
"

# 生成主脚本
mkdir -p "$HOME/.config/niri/script/"
echo "$SH" > "$HOME/.config/niri/script/mask_kded6.sh"
chmod +x "$HOME/.config/niri/script/mask_kded6.sh"

# 生成 autostart 配置
AUTOSTART="[Desktop Entry]
Comment[zh_CN]=在 niri 下遮蔽 kded6 防止抢占托盘
Comment=Mask kded6 in niri to prevent tray hijacking
Exec=$HOME/.config/niri/script/mask_kded6.sh
Name[zh_CN]=mask_kded6
Name=mask_kded6
StartupNotify=true
Terminal=false
Type=Application
X-KDE-SubstituteUID=false"

mkdir -p "$HOME/.config/autostart"
echo "$AUTOSTART" > "$HOME/.config/autostart/mask_kded6.desktop"

echo "脚本已生成完成！"
echo "- 主脚本: $HOME/.config/niri/script/mask_kded6.sh"
echo "- Autostart: $HOME/.config/autostart/mask_kded6.desktop"
echo ""
echo "运行 $HOME/.config/niri/script/mask_kded6.sh 来立即应用 mask"
