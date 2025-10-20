#!/usr/bin/env bash
# USB 自动挂载 + 通知 + 打开 Dolphin
USER_NAME="busyo"

# 已通知或挂载的分区列表
NOTIFIED_DEVS=()

# 挂载分区并打开 Dolphin
mount_and_open() {
    local DEV="$1"
    MOUNTPOINT=$(udisksctl mount -b "$DEV" 2>/dev/null | awk -F" at " '{print $2}')
    [ -z "$MOUNTPOINT" ] && return
    notify-send -i drive-removable-media "💽 U盘已挂载" "$MOUNTPOINT"
    xdg-open "$MOUNTPOINT"
}

# 弹通知并挂载所有新分区
notify_usb_all() {
    local DEVS=("$@")
    local DEV_LABELS=()

    for DEV in "${DEVS[@]}"; do
        LABEL=$(lsblk -nr -o LABEL "$DEV")
        [ -z "$LABEL" ] && LABEL=$(basename "$DEV")
        DEV_LABELS+=("$LABEL ($DEV)")
    done

     # --wait 等待用户点击，--action 设置按钮
    ACTION=$(notify-send -i drive-removable-media "💽 U盘检测到" "$(printf "%s\n" "${DEV_LABELS[@]}")" \
        --action="mount=挂载并打开" --wait)

    # 如果用户点击按钮，notify-send 会输出按钮名称到 stdout
    if [ "$ACTION" == "mount" ]; then
        # 挂载并打开所有分区
        for DEV in "${DEVS[@]}"; do
            mount_and_open "$DEV"
        done
    fi
}

partial_contains() {
    local str1="$1"
    local str2="$2"
    [[ "$str1" == *"$str2"* ]]
}

# 监听 UDisks2
udisksctl monitor | while read -r line; do
    # 处理插入事件
    if [[ "$line" == *Device:* ]]; then
        sleep 1
        DEVS_TO_MOUNT=()
        for DEV in /dev/sd[b-z][1-9]; do
            echo "dev=$DEV"
            # 跳过已经通知或已挂载
            [[ " ${NOTIFIED_DEVS[*]} " == *" $DEV "* ]] && continue
            MOUNTPOINT=$(lsblk -nr -o MOUNTPOINT "$DEV")
            echo "mount=$MOUNTPOINT"
            [ -n "$MOUNTPOINT" ] && continue

            # 文件系统判断
            FSTYPE=$(lsblk -nr -o FSTYPE "$DEV")
            [ -z "$FSTYPE" ] && continue

            # 跳过小分区 (<100MB)，通常是 EFI/boot
            SIZE=$(lsblk -nr -o SIZE -b "$DEV")
            [ "$SIZE" -lt 100000000 ] && continue

            echo "check $line $DEV"

            if partial_contains "$line" "$DEV"; then
                DEVS_TO_MOUNT+=("$DEV")
                NOTIFIED_DEVS+=("$DEV")
            fi
        done

        [ "${#DEVS_TO_MOUNT[@]}" -gt 0 ] && notify_usb_all "${DEVS_TO_MOUNT[@]}" &
    fi

    # 处理拔出事件，清理已通知列表
    if [[ "$line" == *Removed*block_devices* ]]; then
        for DEV in "${NOTIFIED_DEVS[@]}"; do
            DEV_NAME=$(basename "$LINE")
            echo "check remove "$line" "$DEV""
            if partial_contains "$DEV" "$DEV_NAME"; then
                # 从数组中移除
                NOTIFIED_DEVS=("${NOTIFIED_DEVS[@]/$DEV}")
            fi
        done
    fi
done
