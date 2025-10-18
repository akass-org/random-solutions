# 设置截图文件路径
TPATH="/tmp"

FILENAME="screenshot-$(date +%Y-%m-%d_%H-%M-%S).png"

SCREENSHOT_PATH="$TPATH/$FILENAME"

# 使用 grim 区域截图并保存，注意 -o 指定输出路径
wayfreeze --hide-cursor --after-freeze-cmd "sh -c '
    grim -g \"\$(slurp)\" \"$SCREENSHOT_PATH\";
    killall wayfreeze
'"

echo "截图完成"

sleep 0.1

# 如果文件成功保存
if [ -f "$SCREENSHOT_PATH" ]; then

    # 将文件路径复制到剪贴板（image mime）
    echo -n "file://$SCREENSHOT_PATH" | wl-copy -t text/uri-list

    echo "截图已复制到剪贴板 ✅"
fi

mkdir -p $HOME/.config/niri/script/temp

FLAG_FILE=$HOME/.config/niri/script/temp/screenshot_path
# 写入标志文件
echo "$SCREENSHOT_PATH" > "$FLAG_FILE"
echo "📝 已创建标志文件：$FLAG_FILE"

# # 启动一个后台定时删除任务
# (
#     sleep 5
#     rm -f "$FLAG_FILE"
#     echo "⏱️ 5秒到期，已删除标志文件：$FLAG_FILE"
# ) & disown
