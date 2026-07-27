#!/usr/bin/env bash

# ==========================================================
# 项目名称: XrayR 现代化重构版全功能管理脚本 (精简输出静默检测版)
# 适用系统: Ubuntu / Debian / CentOS / Rocky / Alma / Fedora / Arch / openSUSE / Alpine
# 专属仓库: https://github.com/Deeye/XrayR-AutoInstall
# ==========================================================

set -u

# 霓虹极客配色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
MAGENTA='\033[1;35m'
BOLD='\033[1;32m'
PLAIN='\033[0m'

# 项目核心全局变量
GITHUB_USER="Deeye"
REPO_NAME="XrayR-AutoInstall"
RELEASE_VERSION="v1.0.0"
SYSTEM_CMD_PATH="/usr/local/bin/xrayr"
BACKUP_CONFIG="/tmp/xrayr_config_bak.yml"

# 动态路径变量
CONFIG_DIR="/etc/XrayR"
BINARY_PATH=""
IS_NAT=false

type_effect() {
    local text="$1"
    local delay=0.005
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo ""
}

show_line() {
    echo -e "${CYAN}─${BLUE}─${PURPLE}─${MAGENTA}─${RED}─${YELLOW}─${GREEN}─${CYAN}─${BLUE}─${PURPLE}─${MAGENTA}─${RED}─${YELLOW}─${GREEN}─${CYAN}─${BLUE}─${PURPLE}─${MAGENTA}─${RED}─${YELLOW}─${GREEN}─${CYAN}─${BLUE}─${PURPLE}─${MAGENTA}─${RED}─${YELLOW}─${GREEN}─${CYAN}─${BLUE}─${PURPLE}─${MAGENTA}─${RED}─${YELLOW}─${GREEN}─${CYAN}─${BLUE}─${PURPLE}─${MAGENTA}─${RED}─${YELLOW}─${GREEN}─${CYAN}─${BLUE}─${PURPLE}─${MAGENTA}─${RED}─${YELLOW}─${GREEN}─${CYAN}─${BLUE}─${PURPLE}─${MAGENTA}─${RED}─${YELLOW}─${GREEN}─${PLAIN}"
}

show_banner() {
    clear
    echo -e "${MAGENTA}██╗  ██╗██████╗  █████╗ ██╗   ██╗██████╗     ██████╗ ${PLAIN}"
    echo -e "${PURPLE}╚██╗██╔╝██╔══██╗██╔══██╗╚██╗ ██╔╝██╔══██╗    ██╔══██╗${PLAIN}"
    echo -e "${BLUE} ╚███╔╝ ██████╔╝███████║ ╚████╔╝ ██████╔╝    ██████╔╝${PLAIN}"
    echo -e "${CYAN} ██╔██╗ ██╔══██╗██╔══██║  ╚██╔╝  ██╔══██╗    ██╔══██╗${PLAIN}"
    echo -e "${GREEN}██╔╝ ██╗██║  ██║██║  ██║   ██║   ██║  ██║    ██║  ██║${PLAIN}"
    echo -e "${GREEN}╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝    ╚═╝  ╚═╝${PLAIN}"
    show_line
    echo -e " 🚀 ${BOLD}XrayR 智能NAT自适应控制面板${PLAIN} | ${MAGENTA}Codename: 将进酒${PLAIN}"
    echo -e " 📂 ${YELLOW}开源仓库: https://github.com/${GITHUB_USER}/${REPO_NAME}${PLAIN}"
    show_line
}

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[错误] 本脚本必须以 root 用户身份运行！请执行 sudo -i 切换后重试。${PLAIN}"
    exit 1
fi

# 静默内存检查与 Swap 构建（隐藏冗长输出）
check_and_fix_memory() {
    local total_mem
    total_mem=$(free -m | awk '/Mem:/ {print $2}')
    if [[ -n "$total_mem" && "$total_mem" -lt 300 ]]; then
        if ! grep -q "swap" /proc/swaps; then
            fallocate -l 1G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=1024 2>/dev/null
            chmod 600 /swapfile
            mkswap /swapfile >/dev/null 2>&1
            swapon /swapfile >/dev/null 2>&1
        fi
    fi
}

# 静默 NAT 环境检测（隐藏冗长输出）
detect_environment() {
    local local_ip=""
    local_ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7;exit}')
    if [[ -z "$local_ip" ]]; then
        local_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi

    if [[ "$local_ip" =~ ^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\.|^192\.168\. ]]; then
        IS_NAT=true
    else
        local pub_ip=""
        pub_ip=$(curl -s --max-time 3 https://ipv4.icanhazip.com 2>/dev/null)
        if [[ -n "$pub_ip" && -n "$local_ip" && "$local_ip" != "$pub_ip" ]]; then
            IS_NAT=true
        fi
    fi

    if [[ "$IS_NAT" == "true" ]]; then
        BINARY_PATH="/usr/local/bin/xrayr-core"
    else
        BINARY_PATH="${CONFIG_DIR}/XrayR"
    fi
}

INIT_SYSTEM=""
check_init_system() {
    if [[ -d /run/systemd/system ]] || [[ -L /sbin/init && "$(readlink -f /sbin/init)" == *"systemd"* ]]; then
        INIT_SYSTEM="systemd"
    elif command -v openrc >/dev/null 2>&1 || [[ -f /etc/alpine-release ]] || command -v rc-service >/dev/null 2>&1; then
        INIT_SYSTEM="openrc"
    else
        echo -e "${RED}[错误] 无法识别当前系统的初始化进程！${PLAIN}"
        exit 1
    fi
}
check_init_system
detect_environment

srv_start() { [[ "$INIT_SYSTEM" == "systemd" ]] && systemctl start xrayr || rc-service xrayr start >/dev/null 2>&1; }
srv_stop() { [[ "$INIT_SYSTEM" == "systemd" ]] && systemctl stop xrayr || rc-service xrayr stop >/dev/null 2>&1; }
srv_restart() { [[ "$INIT_SYSTEM" == "systemd" ]] && systemctl restart xrayr || rc-service xrayr restart >/dev/null 2>&1; }
srv_status() { [[ "$INIT_SYSTEM" == "systemd" ]] && systemctl status xrayr --no-pager -l || rc-service xrayr status; }
srv_is_active() { [[ "$INIT_SYSTEM" == "systemd" ]] && systemctl is-active xrayr >/dev/null 2>&1 || rc-service xrayr status 2>&1 | grep -Eqi "started|running"; }
srv_enable() { [[ "$INIT_SYSTEM" == "systemd" ]] && systemctl enable xrayr >/dev/null 2>&1 || rc-update add xrayr default >/dev/null 2>&1; }
srv_disable() { [[ "$INIT_SYSTEM" == "systemd" ]] && systemctl disable xrayr >/dev/null 2>&1 || rc-update del xrayr default >/dev/null 2>&1; }
srv_logs() {
    if [[ "$INIT_SYSTEM" == "systemd" ]]; then
        journalctl -u xrayr -f -n 50
    else
        touch /var/log/xrayr.log
        tail -f -n 50 /var/log/xrayr.log
    fi
}

get_architecture() {
    local arch=$(uname -m)
    case "${arch}" in
        x86_64|amd64) echo "64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l|armv6l) echo "arm" ;;
        *) echo -e "${RED}[错误] 不支持的 CPU 架构: ${arch}${PLAIN}"; exit 1 ;;
    esac
}

install_dependencies() {
    type_effect "${BLUE}➜ 正在检查系统基础运行环境...${PLAIN}"
    if command -v curl >/dev/null 2>&1 && command -v wget >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
        type_effect "${GREEN}✔ 基础依赖已就绪。${PLAIN}"
        return 0
    fi

    type_effect "${YELLOW}➜ 正在同步缺失的基础运行工具...${PLAIN}"
    if command -v apt-get >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq >/dev/null 2>&1
        apt-get install -y -qq curl wget unzip ca-certificates file >/dev/null 2>&1
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y -q curl wget unzip ca-certificates file >/dev/null 2>&1
    elif command -v yum >/dev/null 2>&1; then
        yum install -y -q curl wget unzip ca-certificates file >/dev/null 2>&1
    elif command -v apk >/dev/null 2>&1; then
        apk update -q >/dev/null 2>&1
        apk add --no-cache curl wget unzip ca-certificates bash openrc file gcompat libc6-compat >/dev/null 2>&1
    fi
}

show_install_process() {
    show_banner
    type_effect "${YELLOW}[1/4] 🚀 正在初始化系统运行环境...${PLAIN}"
    check_and_fix_memory
    install_dependencies
    
    type_effect "${YELLOW}\n[2/4] 📂 正在安全构建配置目录 ${CONFIG_DIR} ...${PLAIN}"
    mkdir -p ${CONFIG_DIR}
    if [ -f "${CONFIG_DIR}/config.yml" ]; then
        cp -f ${CONFIG_DIR}/config.yml ${BACKUP_CONFIG}
    fi
    
    srv_stop 2>/dev/null || true

    type_effect "${YELLOW}\n[3/4] 🌐 正在拉取核心二进制主程序...${PLAIN}"
    ARCH=$(get_architecture)
    RAW_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}/releases/download/${RELEASE_VERSION}/XrayR-linux-${ARCH}.zip"
    
    TEMP_DIR="/tmp/xrayr_install_tmp"
    rm -rf ${TEMP_DIR}
    mkdir -p ${TEMP_DIR}
    cd ${TEMP_DIR}

    if ! wget -t 3 -T 15 -q --no-check-certificate -O XrayR.zip "${RAW_URL}"; then
        echo -e "${RED}[错误] 下载失败，请检查网络。${PLAIN}"
        rm -rf ${TEMP_DIR}
        exit 1
    fi

    unzip -q -o XrayR.zip
    if [[ ! -f "XrayR" ]]; then
        echo -e "${RED}[错误] 解压未找到主程序文件。${PLAIN}"
        rm -rf ${TEMP_DIR}
        exit 1
    fi

    chmod +x XrayR

    if [[ "$IS_NAT" == "true" ]]; then
        mv -f XrayR ${BINARY_PATH}
    else
        mv -f XrayR ${CONFIG_DIR}/XrayR
    fi
    rm -rf ${TEMP_DIR}

    type_effect "${BLUE}➜ 正在执行程序兼容性自检...${PLAIN}"
    ${BINARY_PATH} --version || ${BINARY_PATH} -version
    local exec_status=$?

    if [ ${exec_status} -ne 0 ]; then
        echo -e "\n${RED}[严重错误] 二进制程序执行失败，退出状态码: ${exec_status}${PLAIN}"
        exit 1
    fi
    type_effect "${GREEN}✔ 二进制自检通过！${PLAIN}"

    if [ -f "${BACKUP_CONFIG}" ]; then
        mv -f ${BACKUP_CONFIG} ${CONFIG_DIR}/config.yml
        rm -f ${BACKUP_CONFIG}
    fi
    [[ -f "${CONFIG_DIR}/config.yml" ]] && chmod 600 ${CONFIG_DIR}/config.yml

    type_effect "${YELLOW}\n[4/4] ⚙️ 正在向 [${INIT_SYSTEM^^}] 守护进程注册服务...${PLAIN}"
    
    if [[ "$INIT_SYSTEM" == "systemd" ]]; then
        cat > /etc/systemd/system/xrayr.service <<EOF
[Unit]
Description=XrayR Backend Service (Silent Optimized Edition)
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=${CONFIG_DIR}
ExecStart=${BINARY_PATH} --config ${CONFIG_DIR}/config.yml
Restart=on-failure
RestartSec=10s
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
    fi

    srv_enable
     
    if curl -sL --connect-timeout 15 "https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/main/install.sh" | sed 's/\r$//' > "/tmp/xrayr_temp.sh"; then
        if [[ -s "/tmp/xrayr_temp.sh" ]]; then
            mv -f "/tmp/xrayr_temp.sh" ${SYSTEM_CMD_PATH}
            chmod +x ${SYSTEM_CMD_PATH}
            ln -sf ${SYSTEM_CMD_PATH} /usr/local/bin/XrayR >/dev/null 2>&1
        fi
    fi
    rm -f "/tmp/xrayr_temp.sh"

    type_effect "${GREEN}✔ 安装成功！输入 xrayr 即可管理。${PLAIN}"
    show_manage_menu
}

uninstall_xrayr() {
    srv_stop
    srv_disable
    rm -rf ${CONFIG_DIR} ${SYSTEM_CMD_PATH} /usr/local/bin/XrayR /etc/systemd/system/xrayr.service
    [[ -f "/usr/local/bin/xrayr-core" ]] && rm -f /usr/local/bin/xrayr-core
    [[ "$INIT_SYSTEM" == "systemd" ]] && systemctl daemon-reload >/dev/null 2>&1
    echo -e "${GREEN}卸载完成。${PLAIN}"
    exit 0
}

show_manage_menu() {
    while true; do
        show_banner
        if srv_is_active; then
            echo -e " 🟢 运行状态: ${GREEN}正常运行中${PLAIN}"
        else
            echo -e " 🔴 运行状态: ${RED}已停止${PLAIN}"
        fi
        show_line
        echo -e "  ${GREEN}1.${PLAIN} 启动服务"
        echo -e "  ${GREEN}2.${PLAIN} 停止服务"
        echo -e "  ${GREEN}3.${PLAIN} 重启服务"
        echo -e "  ${GREEN}4.${PLAIN} 查看日志"
        echo -e "  ${GREEN}6.${PLAIN} 修改配置文件 (${CONFIG_DIR}/config.yml)"
        echo -e "  ${RED}10.${PLAIN} 卸载"
        echo -e "  ${RED}0.${PLAIN} 退出"
        show_line
        read -p " 请选择 [0-10]: " menu_num
        case "${menu_num:-}" in
            1) srv_start; sleep 1.5 ;;
            2) srv_stop; sleep 1.5 ;;
            3) srv_restart; sleep 1.5 ;;
            4) srv_logs ;;
            6)
                if [ -f "${CONFIG_DIR}/config.yml" ]; then
                    nano ${CONFIG_DIR}/config.yml || vi ${CONFIG_DIR}/config.yml
                    srv_restart
                else
                    echo -e "${RED}[错误] 配置文件不存在${PLAIN}"
                fi
                sleep 1.5
                ;;
            10) uninstall_xrayr ;;
            0) exit 0 ;;
        esac
    done
}

SCRIPT_NAME=$(basename "$0")
if [[ "$SCRIPT_NAME" == "xrayr" || "$SCRIPT_NAME" == "XrayR" || "${1:-}" == "menu" ]]; then
    show_manage_menu
else
    if [[ (-f "${BINARY_PATH}" || -f "${CONFIG_DIR}/XrayR") && -d "${CONFIG_DIR}" ]]; then
        show_manage_menu
    else
        show_install_process
    fi
fi
