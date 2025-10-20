#!/bin/bash

mkdir -p "$HOME/.config/niri/script/appManager/"
APPLIST="$HOME/.config/niri/script/appManager/applist.txt"

CUR_MON=$(niri msg --json focused-output | jq -r .name)

partial_contains() {
    local str1="$1"
    local str2="$2"
    [[ "$str1" == *"$str2"* ]] || [[ "$str2" == *"$str1"* ]]
}

mkdir -p "/tmp/start_app/"
APP="/tmp/start_app/app"
BLOCK="/tmp/start_app/block"
EXIT_CODE="/tmp/start_app/exit"

echo "" > $APP
echo "" > $BLOCK
echo 0 > $EXIT_CODE

event_monitor(){
    echo "Starting"
    # 后台监听 niri 事件流
    niri msg --json event-stream | while IFS= read -r line; do
        # 获取事件名（JSON 的第一个 key）
        event_name=$(echo "$line" | jq -r 'keys[0] // empty')
        case "$event_name" in
                "WindowOpenedOrChanged")
                    app=$(< $APP)
                    block=$(< $BLOCK)
#                     echo "$line"
                    title=$(echo "$line" | jq -r '.WindowOpenedOrChanged.window.title')
                    app_id=$(echo "$line" | jq -r '.WindowOpenedOrChanged.window.app_id')
                    echo "check block $block and $title"
                    if [[ "${block,,}" != "${title,,}" ]]; then
                        echo "check app == $app"
                       if [[ -n "$app" ]]; then
                            echo "monit app => $app and $app_id"
                            if partial_contains "${app,,}" "${app_id,,}"; then
                               echo "匹配到app=$app_id title=$title block=$block"
#                             break
                                echo 1 > $EXIT_CODE
                            fi
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

event_monitor &

sleep 5

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

    exit_code=$(< $EXIT_CODE)
    while [[ $exit_code == 0 ]]; do
        exit_code=$(< $EXIT_CODE)
        echo $app > $APP
        echo $block > $BLOCK
#         echo "set data ==> $APP"
    done

    echo 0 > $EXIT_CODE

     if [[ -n $monitor ]]; then
        niri msg action move-window-to-monitor $monitor
    fi

    if [[ -n $workspace ]]; then
        niri msg action move-window-to-workspace $workspace --focus false
    fi

done < $APPLIST

echo "done"

niri msg action focus-monitor $CUR_MON

rm -rf "/tmp/start_app/"

kill -- -$$
