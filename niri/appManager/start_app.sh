#!/bin/bash

mkdir -p "$HOME/.config/niri/script/appManager/"
APPLIST="$HOME/.config/niri/script/appManager/applist.txt"

CUR_MON=$(niri msg --json focused-output | jq -r .name)

partial_contains() {
    local str1="$1"
    local str2="$2"
    [[ "$str1" == *"$str2"* ]]
}

event_monitor(){
    app=${1,,}
    block=${2,,}
    # 后台监听 niri 事件流
    niri msg --json event-stream | while IFS= read -r line; do
        # 获取事件名（JSON 的第一个 key）
        event_name=$(echo "$line" | jq -r 'keys[0] // empty')
        case "$event_name" in
                "WindowOpenedOrChanged")
                    echo "$line"
                    title=$(echo "$line" | jq -r '.WindowOpenedOrChanged.window.title')
                    app_id=$(echo "$line" | jq -r '.WindowOpenedOrChanged.window.app_id')
                    echo "monit app => $title"
                    echo "check block $block and $title"
                    if [[ "$block" != "${title,,}" ]]; then
                       if partial_contains "$app" "${app_id,,}"; then
                            echo "匹配到app=$app_id title=$title block=$block"
                            break
                        fi
                    fi
                ;;
            *)
                # 其他事件可忽略或打印调试
                # echo "其他事件: $event_name"
                ;;
        esac
    done
}

sleep 1

while IFS= read -r line; do

    # 去掉前后空白
    line="${line##+([[:space:]])}"
    line="${line%%+([[:space:]])}"

    # 跳过空行和以 # 开头的行
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    # 用 ':' 拆分为数组
    IFS=':' read -r -a parts <<< "$line"

    app="${parts[0]}"
    workspace="${parts[1]:-}"
    monitor="${parts[2]:-}"
    block="${parts[3]:-}"

    echo "App: $app, Workspace: $workspace, Monitor: $monitor"

    nohup gtk-launch $app  >/dev/null 2>&1 &

    event_monitor "$app" "$block"

     if [[ -n $monitor ]]; then
        niri msg action move-window-to-monitor $monitor
    fi

    if [[ -n $workspace ]]; then
        niri msg action move-window-to-workspace $workspace --focus false
    fi

done < $APPLIST

niri msg action focus-monitor $CUR_MON
