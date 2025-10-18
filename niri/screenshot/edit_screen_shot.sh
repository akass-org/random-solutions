#!/bin/bash

FLAG_FILE=$HOME/.config/niri/script/temp/screenshot_path

if [ -f "$FLAG_FILE" ]; then
    read -r SCREENSHOT_PATH < "$FLAG_FILE"
    echo "编辑截图：$SCREENSHOT_PATH"

    # 记录原始文件信息
    original_size=0
    original_mtime=0
    if [ -f "$SCREENSHOT_PATH" ]; then
        original_size=$(stat -c%s "$SCREENSHOT_PATH")
        original_mtime=$(stat -c%Y "$SCREENSHOT_PATH")
    fi

    satty --no-window-decoration \
          --disable-notifications \
          --action-on-enter save-to-file \
          --early-exit \
          --initial-tool rectangle \
          --profile-startup \
          -f "$SCREENSHOT_PATH" -o "$SCREENSHOT_PATH"

    # 编辑后检查
    if [ -f "$SCREENSHOT_PATH" ]; then
        new_size=$(stat -c%s "$SCREENSHOT_PATH")
        new_mtime=$(stat -c%Y "$SCREENSHOT_PATH")
        if [ "$new_size" -ne "$original_size" ] || [ "$new_mtime" -ne "$original_mtime" ]; then
            rm $FLAG_FILE
            echo "截图被修改了 ✅"

            echo -n "file://$SCREENSHOT_PATH" | wl-copy -t text/uri-list
            echo "截图已复制到剪贴板 ✅"
        else
            echo "截图未修改 ❌"
        fi
    fi
else
    echo "⏱️ 没有可编辑的截图（标志文件不存在）"
fi
