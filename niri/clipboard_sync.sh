#!/bin/bash

# 颜色定义
COLOR_RESET="\033[0m"
COLOR_GREEN="\033[32m"
COLOR_BLUE="\033[34m"
COLOR_YELLOW="\033[33m"
COLOR_CYAN="\033[36m"

# 日志函数
log() {
    local timestamp=$(date '+%H:%M:%S')
    echo -e "${COLOR_CYAN}[$timestamp]${COLOR_RESET} $1"
}

log_sync() {
    local direction=$1
    local type=$2
    local format=$3

    case "$direction" in
        "x11->wl")
            echo -e "${COLOR_CYAN}[$(date '+%H:%M:%S')]${COLOR_RESET} ${COLOR_GREEN}✓${COLOR_RESET} X11 → Wayland | ${COLOR_YELLOW}${type}${COLOR_RESET}${format}"
            ;;
        "wl->x11")
            echo -e "${COLOR_CYAN}[$(date '+%H:%M:%S')]${COLOR_RESET} ${COLOR_BLUE}✓${COLOR_RESET} Wayland → X11 | ${COLOR_YELLOW}${type}${COLOR_RESET}${format}"
            ;;
    esac
}

# 检查依赖
check_dependencies() {
    local missing_deps=()
    for cmd in xclip wl-paste wl-copy sha256sum; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "错误：缺少以下依赖命令：${missing_deps[*]}" >&2
        echo "请安装相应的软件包后重试" >&2
        exit 1
    fi
}

# 防抖变量
last_text=""
last_x11_img_hash=""  # 上次从 X11 同步到 Wayland 的图片哈希
last_wl_img_hash=""   # 上次从 Wayland 同步到 X11 的图片哈希

# 剪切板同步主循环
clipboard_sync() {
    while true; do
        img_synced=false  # 标记本轮是否已同步图片

        # -------- 图片同步：X11 → Wayland --------
        x11_targets=$(xclip -selection clipboard -t TARGETS -o 2>/dev/null || true)
        x11_img_type=""
        if echo "$x11_targets" | grep -q "image/png"; then
            x11_img_type="image/png"
        elif echo "$x11_targets" | grep -q "image/jpeg"; then
            x11_img_type="image/jpeg"
        elif echo "$x11_targets" | grep -q "image/gif"; then
            x11_img_type="image/gif"
        fi

        if [[ -n "$x11_img_type" ]]; then
            if [[ $(xclip -selection clipboard -t "$x11_img_type" -o 2>/dev/null | wc -c) -gt 0 ]]; then
                x11_img_hash=$(xclip -selection clipboard -t "$x11_img_type" -o 2>/dev/null | sha256sum | awk '{print $1}')

                if [[ -n "$x11_img_hash" && "$x11_img_hash" != "$last_x11_img_hash" ]]; then
                    # 直接将图片数据传输到 Wayland 剪切板
                    xclip -selection clipboard -t "$x11_img_type" -o 2>/dev/null | wl-copy -t "$x11_img_type"
                    last_x11_img_hash="$x11_img_hash"
                    last_wl_img_hash="$x11_img_hash"
                    img_synced=true
                    log_sync "x11->wl" "图片" " ($x11_img_type)"
                    # 清空 X11 剪切板，让 Wayland 成为唯一数据源
                    xclip -selection clipboard -i /dev/null
                fi
            fi
        fi

        # -------- 图片同步：Wayland → X11 --------
        # 只在本轮未同步图片时才检查 Wayland → X11
        if [[ "$img_synced" == false ]]; then
            wl_types=$(wl-paste --list-types 2>/dev/null || true)
            wl_img_type=""
            if echo "$wl_types" | grep -q "image/png"; then
                wl_img_type="image/png"
            elif echo "$wl_types" | grep -q "image/jpeg"; then
                wl_img_type="image/jpeg"
            elif echo "$wl_types" | grep -q "image/gif"; then
                wl_img_type="image/gif"
            fi

            if [[ -n "$wl_img_type" ]]; then
                # 使用管道直接传输二进制数据，计算哈希来防抖
                wl_img_hash=$(wl-paste -t "$wl_img_type" 2>/dev/null | tee >(sha256sum | awk '{print $1}' > /tmp/wl_hash_$$) | cat > /dev/null; cat /tmp/wl_hash_$$ 2>/dev/null; rm -f /tmp/wl_hash_$$ 2>/dev/null)

                # 如果 Wayland 的图片与上次同步的不同，则同步到 X11
                if [[ -n "$wl_img_hash" && "$wl_img_hash" != "$last_wl_img_hash" ]]; then
                    wl-paste -t "$wl_img_type" 2>/dev/null | xclip -selection clipboard -t "$wl_img_type" -i
                    last_wl_img_hash="$wl_img_hash"
                    last_x11_img_hash="$wl_img_hash"
                    img_synced=true  # 标记已同步图片，跳过本轮文本同步
                    log_sync "wl->x11" "图片" " ($wl_img_type)"
                fi
            fi
        fi

        # -------- 文本同步 --------
        # 只在未同步图片时才进行文本同步
        if [[ "$img_synced" == false ]]; then
            text_synced=false  # 标记本轮是否已同步文本
            current_text=$(wl-paste --type text/plain 2>/dev/null || true)

            # 只在 X11 剪切板包含文本时才读取，避免读取二进制数据导致警告
            x11_text=""
            if [[ -z "$x11_img_type" ]]; then
                x11_text=$(xclip -selection clipboard -o 2>/dev/null || true)
            fi

            if [[ -n "$x11_text" && "$x11_text" != "$last_text" && "$x11_text" != "$current_text" ]]; then
                echo -n "$x11_text" | wl-copy --type text/plain
                last_text="$x11_text"
                text_synced=true
                # 显示文本预览（最多 50 个字符），换行符替换为 ↵
                local preview=$(echo -n "$x11_text" | head -c 50 | iconv -f utf-8 -t utf-8 -c)
                preview="${preview//$'\n'/↵}"
                preview="${preview//$'\r'/}"
                preview="${preview//$'\t'/⇥}"
                [[ ${#x11_text} -gt 50 ]] && preview="${preview}..."
                log_sync "x11->wl" "文本" " \"$preview\""
            fi

            # 只在本轮未同步文本时才检查 Wayland → X11
            if [[ "$text_synced" == false && -n "$current_text" && "$current_text" != "$last_text" && "$x11_text" != "$current_text" ]]; then
                echo "$current_text" | xclip -selection clipboard -t UTF8_STRING -i
                last_text="$current_text"
                # 显示文本预览（最多 50 个字符），换行符替换为 ↵
                local preview=$(echo -n "$current_text" | head -c 50 | iconv -f utf-8 -t utf-8 -c)
                preview="${preview//$'\n'/↵}"
                preview="${preview//$'\r'/}"
                preview="${preview//$'\t'/⇥}"
                [[ ${#current_text} -gt 50 ]] && preview="${preview}..."
                log_sync "wl->x11" "文本" " \"$preview\""
            fi
        fi

        sleep 0.5
    done
}

# 设置退出时清理
trap 'exit' INT TERM EXIT

# 依赖检查
check_dependencies

log "剪切板同步服务已启动"
log "监控 Wayland ↔ X11 剪切板同步..."

# 启动同步服务
clipboard_sync
