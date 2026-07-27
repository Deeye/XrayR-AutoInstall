#!/usr/bin/env bash

# ==========================================================
# XrayR-AutoInstall
# XrayR 智能安装与管理脚本 (NAT & VPS 全面优化版)
# 版本: v1.0.2
# 支持: Ubuntu / Debian / CentOS / Rocky / Alma / Fedora / Arch / openSUSE / Alpine
# ==========================================================

set -Eeuo pipefail

# -----------------------------
# 基础配置
# -----------------------------
GITHUB_USER="Deeye"
REPO_NAME="XrayR-AutoInstall"
RELEASE_VERSION="v1.0.0"

CONFIG_DIR="/etc/XrayR"
SYSTEM_CMD_PATH="/usr/local/bin/xrayr"
NAT_BINARY_PATH="/usr/local/bin/xrayr-core"
SERVICE_FILE="/etc/systemd/system/xrayr.service"

BACKUP_CONFIG="${CONFIG_DIR}/xrayr_config_bak.yml"
TEMP_DIR="${CONFIG_DIR}/.xrayr_install_tmp"

IS_NAT=false
INIT_SYSTEM=""
BINARY_PATH=""

# -----------------------------
# 终端颜色
# -----------------------------
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'

# -----------------------------
# 基础 UI
# -----------------------------
show_line() {
    printf '%b\n' "${DIM}${BLUE}────────────────────────────────────────────────────────────────────${RESET}"
}

show_header() {
    printf '%b\n' "${CYAN}╭────────────────────────────────────────────────────────────────────╮${RESET}"
    printf '%b\n' "${CYAN}│${RESET} ${BOLD}${WHITE}XrayR${RESET} ${DIM}·${RESET} ${GREEN}智能安装与管理面板${RESET} (NAT & VPS 兼容版)             ${CYAN}│${RESET}"
    printf '%b\n' "${CYAN}│${RESET} ${DIM}稳定 · 简洁 · 高效 · 自动部署${RESET}                         ${CYAN}│${RESET}"
    printf '%b\n' "${CYAN}╰────────────────────────────────────────────────────────────────────╯${RESET}"
}

show_banner() {
    clear 2>/dev/null || true
    printf '%b\n' "${MAGENTA}██╗  ██╗██████╗  █████╗ ██╗   ██╗██████╗${RESET}"
    printf '%b\n' "${MAGENTA}╚██╗██╔╝██╔══██╗██╔══██╗╚██╗ ██╔╝██╔══██╗${RESET}"
    printf '%b\n' "${BLUE} ╚███╔╝ ██████╔╝███████║ ╚████╔╝ ██████╔╝${RESET}"
    printf '%b\n' "${CYAN} ██╔██╗ ██╔══██╗██╔══██║  ╚██╔╝  ██╔══██╗${RESET}"
    printf '%b\n' "${GREEN}██╔╝ ██╗██║  ██║██║  ██║   ██║   ██║  ██║${RESET}"
    printf '%b\n' "${GREEN}╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝${RESET}"
    echo
    show_header
    printf '%b\n' " ${DIM}仓库: https://github.com/${GITHUB_USER}/${REPO_NAME}${RESET}"
    show_line
}

section_title() {
    local title="$1"
    local subtitle="${2:-}"
    echo
    printf '%b\n' "${BOLD}${CYAN}◆ ${title}${RESET}"
    [[ -n "${subtitle}" ]] && printf '%b\n' "  ${DIM}${subtitle}${RESET}"
    show_line
}

status_ok() {
    printf '%b\n' "  ${GREEN}✔${RESET} $1"
}

status_warn() {
    printf '%b\n' "  ${YELLOW}⚠${RESET} $1"
}

status_error() {
    printf '%b\n' "  ${RED}✖${RESET} $1"
}

pause_screen() {
    echo
    read -r -p "  按 Enter 返回..." _
}

# -----------------------------
# 异常处理
# -----------------------------
cleanup() {
    rm -rf "${TEMP_DIR}" 2>/dev/null || true
}

on_error() {
    local exit_code=$?
    echo
    status_error "脚本执行失败，退出码: ${exit_code}"
    echo -e "  ${DIM}如果系统发生重启，请检查上一次启动的内核日志：${RESET}"
    echo -e "  ${DIM}journalctl -b -1 -k | grep -Ei 'oom|out of memory|killed process|panic|watchdog'${RESET}"
    exit "${exit_code}"
}

trap cleanup EXIT
trap on_error ERR
trap 'exit 130' INT TERM

# -----------------------------
# 权限与系统检测
# -----------------------------
require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        status_error "本脚本必须以 root 用户运行。"
        echo -e "  ${DIM}请执行: sudo -i${RESET}"
        exit 1
    fi
}

check_init_system() {
    if [[ -d /run/systemd/system ]] ||
       { [[ -L /sbin/init ]] && [[ "$(readlink -f /sbin/init 2>/dev/null || true)" == *systemd* ]]; }; then
        INIT_SYSTEM="systemd"
    elif command -v rc-service >/dev/null 2>&1 ||
         command -v openrc >/dev/null 2>&1 ||
         [[ -f /etc/alpine-release ]]; then
        INIT_SYSTEM="openrc"
    else
        status_error "无法识别当前系统的初始化系统。"
        exit 1
    fi
}

# -----------------------------
# 服务管理
# -----------------------------
srv_start() {
    if [[ "${INIT_SYSTEM}" == "systemd" ]]; then
        systemctl start xrayr
    else
        rc-service xrayr start
    fi
}

srv_stop() {
    if [[ "${INIT_SYSTEM}" == "systemd" ]]; then
        systemctl stop xrayr >/dev/null 2>&1 || true
    else
        rc-service xrayr stop >/dev/null 2>&1 || true
    fi
}

srv_restart() {
    if [[ "${INIT_SYSTEM}" == "systemd" ]]; then
        systemctl restart xrayr
    else
        rc-service xrayr restart
    fi
}

srv_enable() {
    if [[ "${INIT_SYSTEM}" == "systemd" ]]; then
        systemctl enable xrayr >/dev/null 2>&1
    else
        rc-update add xrayr default >/dev/null 2>&1
    fi
}

srv_disable() {
    if [[ "${INIT_SYSTEM}" == "systemd" ]]; then
        systemctl disable xrayr >/dev/null 2>&1 || true
    else
        rc-update del xrayr default >/dev/null 2>&1 || true
    fi
}

srv_is_active() {
    if [[ "${INIT_SYSTEM}" == "systemd" ]]; then
        systemctl is-active --quiet xrayr
    else
        rc-service xrayr status >/dev/null 2>&1
    fi
}

srv_logs() {
    if [[ "${INIT_SYSTEM}" == "systemd" ]]; then
        journalctl -u xrayr -f -n 50
    else
        touch /var/log/xrayr.log
        tail -f -n 50 /var/log/xrayr.log
    fi
}

# -----------------------------
# 环境检测
# -----------------------------
get_architecture() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l|armv6l)
            echo "arm"
            ;;
        *)
            status_error "不支持的 CPU 架构: $(uname -m)"
            exit 1
            ;;
    esac
}

detect_environment() {
    section_title "环境检测" "识别网络环境与部署方式"

    local local_ip=""
    local public_ip=""

    if command -v ip >/dev/null 2>&1; then
        local_ip="$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || true)"
    fi

    if [[ -z "${local_ip}" ]]; then
        local_ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
    fi

    if [[ "${local_ip}" =~ ^10\. ]] ||
       [[ "${local_ip}" =~ ^192\.168\. ]] ||
       [[ "${local_ip}" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]]; then
        IS_NAT=true
    else
        public_ip="$(curl -4 -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)"
        if [[ -n "${local_ip}" && -n "${public_ip}" && "${local_ip}" != "${public_ip}" ]]; then
            IS_NAT=true
        fi
    fi

    if [[ "${IS_NAT}" == "true" ]]; then
        printf '%b\n' "  ${YELLOW}●${RESET} 网络环境  ${BOLD}NAT / 内网环境${RESET}"
        printf '%b\n' "  ${DIM}└─${RESET} 部署方式  二进制与配置分离"
        BINARY_PATH="${NAT_BINARY_PATH}"
    else
        printf '%b\n' "  ${GREEN}●${RESET} 网络环境  ${BOLD}独立公网服务器${RESET}"
        printf '%b\n' "  ${DIM}└─${RESET} 部署方式  标准部署"
        BINARY_PATH="${CONFIG_DIR}/XrayR"
    fi

    printf '%b\n' "  ${DIM}└─${RESET} 初始化系统  ${INIT_SYSTEM}"
    show_line
}

# -----------------------------
# 依赖安装
# -----------------------------
install_dependencies() {
    printf '%b\n' "  ${BLUE}▸${RESET} 检查基础依赖 ${DIM}(curl / wget / unzip / ca-certificates)${RESET}"

    if command -v curl >/dev/null 2>&1 &&
       command -v wget >/dev/null 2>&1 &&
       command -v unzip >/dev/null 2>&1; then
        status_ok "基础依赖已全部就绪"
        return 0
    fi

    if command -v apt-get >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq curl wget unzip ca-certificates
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y -q curl wget unzip ca-certificates
    elif command -v yum >/dev/null 2>&1; then
        yum install -y -q curl wget unzip ca-certificates
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache curl wget unzip ca-certificates bash openrc
    else
        status_error "未找到支持的系统包管理器。"
        exit 1
    fi

    status_ok "依赖组件安装完成"
}

# -----------------------------
# 安全资源检查
# -----------------------------
check_resources() {
    local available_mem_kb=0
    local available_disk_kb=0

    if [[ -r /proc/meminfo ]]; then
        available_mem_kb="$(awk '/MemAvailable:/ {print $2; exit}' /proc/meminfo || true)"
        if [[ -z "${available_mem_kb}" ]]; then
            available_mem_kb="$(awk '/MemFree:/ {print $2; exit}' /proc/meminfo || true)"
        fi
    fi

    available_disk_kb="$(df -Pk "${TEMP_DIR}" | awk 'NR==2 {print $4}')"

    if [[ "${available_mem_kb:-0}" =~ ^[0-9]+$ ]] && (( available_mem_kb > 0 )); then
        if (( available_mem_kb < 65536 )); then
            status_warn "当前可用内存较低: ${available_mem_kb} KB"
            status_warn "低内存 NAT VPS 可能被宿主机 OOM 机制重启"
        else
            status_ok "可用内存检查通过"
        fi
    fi

    if [[ "${available_disk_kb:-0}" =~ ^[0-9]+$ ]]; then
        if (( available_disk_kb < 131072 )); then
            status_error "临时目录可用磁盘空间不足"
            exit 1
        else
            status_ok "可用磁盘空间检查通过"
        fi
    fi
}

# -----------------------------
# 下载与解压
# -----------------------------
download_and_extract() {
    local arch="$1"
    local raw_url="https://github.com/${GITHUB_USER}/${REPO_NAME}/releases/download/${RELEASE_VERSION}/XrayR-linux-${arch}.zip"
    local zip_file="${TEMP_DIR}/XrayR.zip"
    local extract_dir="${TEMP_DIR}/extract"

    mkdir -p "${TEMP_DIR}" "${extract_dir}"

    printf '%b\n' "  ${BLUE}▸${RESET} 下载核心程序 ${DIM}架构: ${arch}${RESET}"

    if ! curl -4 -fL --retry 3 --retry-delay 2 --connect-timeout 15 --max-time 300 \
        -o "${zip_file}" "${raw_url}"; then
        status_error "核心程序下载失败，请检查网络连接或 Release 文件名。"
        exit 1
    fi

    if [[ ! -s "${zip_file}" ]]; then
        status_error "下载文件为空。"
        exit 1
    fi

    printf '%b\n' "  ${BLUE}▸${RESET} 检查系统资源"
    check_resources

    printf '%b\n' "  ${BLUE}▸${RESET} 解压程序包 ${DIM}使用独立临时目录，避免覆盖系统文件${RESET}"

    rm -rf "${extract_dir}"
    mkdir -p "${extract_dir}"

    if ! unzip -q -o "${zip_file}" -d "${extract_dir}"; then
        status_error "解压失败。"
        status_warn "如果机器在此阶段重启，请优先检查宿主机 OOM、内核 panic 或 watchdog 日志。"
        exit 1
    fi

    local extracted_binary=""
    extracted_binary="$(find "${extract_dir}" -type f -name "XrayR" -print -quit)"

    if [[ -z "${extracted_binary}" || ! -f "${extracted_binary}" ]]; then
        status_error "解压完成，但未找到 XrayR 主程序。"
        exit 1
    fi

    chmod 755 "${extracted_binary}"
    install -m 0755 "${extracted_binary}" "${BINARY_PATH}"

    status_ok "核心程序已部署至 ${BINARY_PATH}"
}

# -----------------------------
# 二进制自检 (修复版本指令兼容)
# -----------------------------
check_binary() {
    printf '%b\n' "  ${BLUE}▸${RESET} 执行核心程序自检"

    # XrayR 的正确版本检查方式为子命令: XrayR version
    if "${BINARY_PATH}" version >/dev/null 2>&1 || \
       "${BINARY_PATH}" --version >/dev/null 2>&1 || \
       "${BINARY_PATH}" -version >/dev/null 2>&1; then
        status_ok "核心程序自检通过"
    else
        status_error "核心程序无法正常执行"
        exit 1
    fi
}

# -----------------------------
# 服务注册
# -----------------------------
register_service() {
    section_title "注册系统服务" "配置开机启动与后台运行"

    if [[ "${INIT_SYSTEM}" == "systemd" ]]; then
        cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=XrayR Backend Service
After=network-online.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
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
        status_ok "systemd 服务已注册"
    else
        cat > /etc/init.d/xrayr <<EOF
#!/sbin/openrc-run

name="xrayr"
description="XrayR Backend Service"
command="${BINARY_PATH}"
command_args="--config ${CONFIG_DIR}/config.yml"
command_background="yes"
pidfile="/run/\${RC_SVCNAME}.pid"
output_log="/var/log/xrayr.log"
error_log="/var/log/xrayr.log"

depend() {
    need net
    after firewall
}
EOF

        chmod 755 /etc/init.d/xrayr
        status_ok "OpenRC 服务已注册"
    fi

    srv_enable
    status_ok "已设置开机自动启动"
}

# -----------------------------
# 安装管理命令
# -----------------------------
install_management_command() {
    printf '%b\n' "  ${BLUE}▸${RESET} 配置全局管理命令 ${BOLD}xrayr${RESET}"

    local temp_script="${CONFIG_DIR}/.xrayr_management_tmp"

    if curl -4 -fsSL --connect-timeout 15 --max-time 60 \
        "https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/main/install.sh" \
        | sed 's/\r$//' > "${temp_script}"; then

        if [[ -s "${temp_script}" ]]; then
            install -m 0755 "${temp_script}" "${SYSTEM_CMD_PATH}"
            ln -sfn "${SYSTEM_CMD_PATH}" /usr/local/bin/XrayR
            rm -f "${temp_script}"
            status_ok "全局管理命令已配置"
            return 0
        fi
    fi

    rm -f "${temp_script}"
    status_warn "远程管理脚本下载失败，跳过快捷命令更新"
}

# -----------------------------
# 安装流程
# -----------------------------
show_install_process() {
    show_banner
    section_title "安装 XrayR" "开始执行全自动部署流程"

    echo -e " ${BOLD}${CYAN}[1/4]${RESET} ${WHITE}初始化系统运行环境${RESET}"
    show_line
    install_dependencies

    echo
    echo -e " ${BOLD}${CYAN}[2/4]${RESET} ${WHITE}准备配置目录与备份${RESET}"
    show_line

    printf '%b\n' "  ${BLUE}▸${RESET} 创建配置目录 ${DIM}${CONFIG_DIR}${RESET}"
    mkdir -p "${CONFIG_DIR}"

    if [[ -f "${CONFIG_DIR}/config.yml" ]]; then
        status_warn "检测到已有配置文件，正在创建备份"
        cp -f "${CONFIG_DIR}/config.yml" "${BACKUP_CONFIG}"
    fi

    srv_stop
    status_ok "配置目录准备完成"

    echo
    echo -e " ${BOLD}${CYAN}[3/4]${RESET} ${WHITE}下载核心程序并执行安全解压${RESET}"
    show_line

    local arch
    arch="$(get_architecture)"
    download_and_extract "${arch}"
    check_binary

    if [[ -f "${BACKUP_CONFIG}" ]]; then
        mv -f "${BACKUP_CONFIG}" "${CONFIG_DIR}/config.yml"
        chmod 600 "${CONFIG_DIR}/config.yml"
        status_ok "已恢复原有配置文件"
    fi

    echo
    echo -e " ${BOLD}${CYAN}[4/4]${RESET} ${WHITE}注册系统服务与管理命令${RESET}"
    show_line

    register_service
    install_management_command

    echo
    printf '%b\n' "${GREEN}${BOLD}╭────────────────────────────────────────────────────────────────────╮${RESET}"
    printf '%b\n' "${GREEN}${BOLD}│${RESET}  🎉 XrayR 安装与部署已成功完成！                              ${GREEN}${BOLD}│${RESET}"
    printf '%b\n' "${GREEN}${BOLD}╰────────────────────────────────────────────────────────────────────╯${RESET}"
    echo
    echo -e "  ${DIM}以后可直接输入${RESET} ${BOLD}${CYAN}xrayr${RESET} ${DIM}打开管理面板${RESET}"

    if [[ ! -f "${CONFIG_DIR}/config.yml" ]]; then
        echo
        status_warn "当前未检测到 config.yml，请先配置后再启动服务"
    fi

    sleep 2
    show_manage_menu
}

# -----------------------------
# 卸载
# -----------------------------
uninstall_xrayr() {
    echo
    read -r -p "  确定要卸载 XrayR 吗？[y/N]: " confirm

    [[ "${confirm}" =~ ^[Yy]$ ]] || return 0

    srv_stop
    srv_disable

    rm -rf "${CONFIG_DIR}"
    rm -f "${SYSTEM_CMD_PATH}" "${NAT_BINARY_PATH}" /usr/local/bin/XrayR

    if [[ "${INIT_SYSTEM}" == "systemd" ]]; then
        rm -f "${SERVICE_FILE}"
        systemctl daemon-reload >/dev/null 2>&1 || true
    else
        rm -f /etc/init.d/xrayr
    fi

    status_ok "XrayR 已卸载"
    exit 0
}

# -----------------------------
# 管理菜单
# -----------------------------
show_manage_menu() {
    while true; do
        show_banner

        if srv_is_active; then
            printf '%b\n' "  ${GREEN}●${RESET} 服务状态  ${GREEN}${BOLD}运行中${RESET}"
        else
            printf '%b\n' "  ${RED}●${RESET} 服务状态  ${RED}${BOLD}已停止${RESET}"
        fi

        echo
        printf '%b\n' "${BOLD}${WHITE}服务操作${RESET}"
        echo -e "  ${GREEN}1${RESET}  启动服务"
        echo -e "  ${GREEN}2${RESET}  停止服务"
        echo -e "  ${GREEN}3${RESET}  重启服务"
        echo -e "  ${GREEN}4${RESET}  查看实时日志"

        echo
        printf '%b\n' "${BOLD}${WHITE}配置管理${RESET}"
        echo -e "  ${GREEN}6${RESET}  编辑配置文件"

        echo
        printf '%b\n' "${BOLD}${WHITE}系统管理${RESET}"
        echo -e "  ${RED}10${RESET} 卸载 XrayR"
        echo -e "  ${RED}0${RESET}  退出面板"

        show_line
        read -r -p "  请输入选项 [0/1/2/3/4/6/10]: " menu_num
        echo

        case "${menu_num:-}" in
            1)
                srv_start
                status_ok "服务启动命令已执行"
                pause_screen
                ;;
            2)
                srv_stop
                status_ok "服务停止命令已执行"
                pause_screen
                ;;
            3)
                srv_restart
                status_ok "服务重启命令已执行"
                pause_screen
                ;;
            4)
                srv_logs
                ;;
            6)
                if [[ -f "${CONFIG_DIR}/config.yml" ]]; then
                    if command -v nano >/dev/null 2>&1; then
                        nano "${CONFIG_DIR}/config.yml"
                    elif command -v vi >/dev/null 2>&1; then
                        vi "${CONFIG_DIR}/config.yml"
                    else
                        status_error "系统中没有找到 nano 或 vi 编辑器"
                    fi

                    if [[ -f "${CONFIG_DIR}/config.yml" ]]; then
                        chmod 600 "${CONFIG_DIR}/config.yml"
                        srv_restart || status_warn "配置已保存，但服务启动失败，请查看日志"
                    fi
                else
                    status_error "配置文件不存在"
                fi
                pause_screen
                ;;
            10)
                uninstall_xrayr
                ;;
            0)
                clear 2>/dev/null || true
                exit 0
                ;;
            *)
                status_warn "无效选项"
                sleep 1
                ;;
        esac
    done
}

# -----------------------------
# 主程序
# -----------------------------
main() {
    require_root
    check_init_system
    detect_environment

    local script_name
    script_name="$(basename "$0")"

    if [[ "${script_name}" == "xrayr" ||
          "${script_name}" == "XrayR" ||
          "${1:-}" == "menu" ]]; then
        show_manage_menu
        return
    fi

    if [[ -x "${BINARY_PATH}" && -d "${CONFIG_DIR}" ]]; then
        show_manage_menu
    else
        show_install_process
    fi
}

main "$@"
