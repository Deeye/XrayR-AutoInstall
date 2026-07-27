#!/usr/bin/env bash

# ==========================================================
# 项目名称: XrayR 现代化重构版全功能管理脚本 (NAT 特化加固版)
# 适用系统: Ubuntu / Debian / CentOS / Rocky / Alma / Fedora / Arch / openSUSE / Alpine
# 专属仓库: https://github.com/Deeye/XrayR-AutoInstall
# ==========================================================

# 错误捕获：防止非致命错误导致管道卡死
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
INSTALL_DIR="/etc/XrayR"
SYSTEM_CMD_PATH="/usr/local/bin/xrayr"
BACKUP_CONFIG="/tmp/xrayr_config_bak.yml"

# 华丽的流式打字机美化特效
type_effect() {
    local text="$1"
    local delay=0.005
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo ""
}

# 炫彩渐变线特效
show_line() {
    echo -e "${CYAN}─${BLUE}─${PURPLE}─${MAGENTA}─${RED}─${YELLOW}─${GREEN}─${CYAN}─${BLUE}─${PURPLE}─${MAGENTA}─${RED}─${YELLOW}─${GREEN}─${CYAN}─${BLUE}─${PURPLE}─${MAGENTA}─${RED}─${YELLOW}─${GREEN}─${CYAN}─${BLUE}─${PURPLE}─${MAGENTA}─${RED}─${YELLOW}─${GREEN}─${CYAN}─${BLUE}─${PURPLE}─${MAGENTA}─${RED}─${YELLOW}─${GREEN}─${CYAN}─${BLUE}─${PURPLE}─${MAGENTA}─${RED}─${YELLOW}─${GREEN}─${CYAN}─${BLUE}─${PURPLE}─${MAGENTA}─${RED}─${YELLOW}─${GREEN}─${CYAN}─${BLUE}─${PURPLE}─${MAGENTA}─${RED}─${YELLOW}─${GREEN}─${PLAIN}"
}

# 3D 霓虹 LOGO Banner
show_banner() {
    clear
    echo -e "${MAGENTA}██╗  ██╗██████╗  █████╗ ██╗   ██╗██████╗     ██████╗ ${PLAIN}"
    echo -e "${PURPLE}╚██╗██╔╝██╔══██╗██╔══██╗╚██╗ ██╔╝██╔══██╗    ██╔══██╗${PLAIN}"
    echo -e "${BLUE} ╚███╔╝ ██████╔╝███████║ ╚████╔╝ ██████╔╝    ██████╔╝${PLAIN}"
    echo -e "${CYAN} ██╔██╗ ██╔══██╗██╔══██║  ╚██╔╝  ██╔══██╗    ██╔══██╗${PLAIN}"
    echo -e "${GREEN}██╔╝ ██╗██║  ██║██║  ██║   ██║   ██║  ██║    ██║  ██║${PLAIN}"
    echo -e "${GREEN}╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝    ╚═╝  ╚═╝${PLAIN}"
    show_line
    echo -e " 🚀 ${BOLD}XrayR NAT 特化加固版 控制面板${PLAIN} | ${MAGENTA}Codename: 将进酒${PLAIN}"
    echo -e " 📂 ${YELLOW}开源仓库: https://github.com/${GITHUB_USER}/${REPO_NAME}${PLAIN}"
    show_line
}

# 严格的 Root 权限检查
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[错误] 本脚本必须以 root 用户身份运行！请执行 sudo -i 切换后重试。${PLAIN}"
    exit 1
fi

# Systemd vs OpenRC 双引擎初始化探测
INIT_SYSTEM=""
check_init_system() {
    if [[ -d /run/systemd/system ]] || [[ -L /sbin/init && "$(readlink -f /sbin/init)" == *"systemd"* ]]; then
        INIT_SYSTEM="systemd"
    elif command -v openrc >/dev/null 2>&1 || [[ -f /etc/alpine-release ]] || command -v rc-service >/dev/null 2>&1; then
        INIT_SYSTEM="openrc"
    else
        echo -e "${RED}[错误] 无法识别当前系统的初始化进程！支持 Systemd 或 OpenRC (Alpine) 守护进程。${PLAIN}"
        exit 1
    fi
}
check_init_system

# 统一服务控制抽象函数
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
        echo -e "${YELLOW}Alpine (OpenRC) 模式：正在读取 /var/log/xrayr.log (按 Ctrl+C 退出)...${PLAIN}"
        touch /var/log/xrayr.log
        tail -f -n 50 /var/log/xrayr.log
    fi
}

get_os_name() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "${PRETTY_NAME:-${ID} ${VERSION_ID:-}}"
    elif [[ -f /etc/redhat-release ]]; then
        cat /etc/redhat-release
    else
        echo "Unknown Linux Distribution"
    fi
}

get_architecture() {
    local arch=$(uname -m)
    case "${arch}" in
        x86_64|amd64) echo "64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l|armv6l) echo "arm" ;;
        s390x) echo "s390x" ;;
        *) echo -e "${RED}[错误] 不支持的 CPU 架构: ${arch}${PLAIN}"; exit 1 ;;
    esac
}

# 依赖免检极速跳过机制 (针对 NAT 环境增加基础工具与兼容库保障)
install_dependencies() {
    local os_name=$(get_os_name)
    type_effect "${BLUE}➜ 识别到系统平台: ${BOLD}${os_name} [${INIT_SYSTEM^^} 引擎]${PLAIN}"
    
    if command -v curl >/dev/null 2>&1 && command -v wget >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1 && command -v ca-certificates >/dev/null 2>&1; then
        type_effect "${GREEN}✔ 系统基础依赖工具已全部就绪，已智能跳过包管理器同步。${PLAIN}"
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
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm --needed curl wget unzip ca-certificates file >/dev/null 2>&1
    elif command -v zypper >/dev/null 2>&1; then
        zypper --non-interactive install -y curl wget unzip ca-certificates file >/dev/null 2>&1
    else
        echo -e "${RED}[错误] 无法识别当前系统的包管理器！支持: apt, dnf, yum, apk, pacman, zypper。${PLAIN}"
        exit 1
    fi
}

# 核心主程序智能安装流程 (NAT 机器特化增强)
show_install_process() {
    show_banner
    type_effect "${YELLOW}[1/4] 🚀 正在初始化系统运行环境与 NAT 适配层...${PLAIN}"
    
    install_dependencies
    
    type_effect "${YELLOW}\n[2/4] 📂 正在安全构建目标运行空间 ${INSTALL_DIR} ...${PLAIN}"
    if [ -f "${INSTALL_DIR}/config.yml" ]; then
        type_effect "${BLUE}➜ 检测到现有历史配置，正在无缝热备份...${PLAIN}"
        cp -f ${INSTALL_DIR}/config.yml ${BACKUP_CONFIG}
    fi
    
    srv_stop 2>/dev/null || true
    rm -rf ${INSTALL_DIR}
    mkdir -p ${INSTALL_DIR}
    cd ${INSTALL_DIR}

    type_effect "${YELLOW}\n[3/4] 🌐 正在通过智能多镜像加速拉取核心二进制主程序 (针对 NAT 网络优化)...${PLAIN}"
    ARCH=$(get_architecture)
    RAW_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}/releases/download/${RELEASE_VERSION}/XrayR-linux-${ARCH}.zip"
    
    MIRROR_URLS=(
        "${RAW_URL}"
        "https://ghproxy.net/${RAW_URL}"
        "https://mirror.ghproxy.com/${RAW_URL}"
    )

    DOWNLOAD_SUCCESS=false
    for url in "${MIRROR_URLS[@]}"; do
        type_effect "${BLUE}➜ 尝试连通镜像源下载: ${url:0:45}...${PLAIN}"
        # 增加超时时间和重试次数，适应 NAT 较慢的网络
        if wget -t 3 -T 15 -q --no-check-certificate -O XrayR.zip "${url}"; then
            if [[ -s "XrayR.zip" ]] && unzip -tq XrayR.zip >/dev/null 2>&1; then
                DOWNLOAD_SUCCESS=true
                break
            else
                rm -f XrayR.zip
            fi
        fi
    done

    if [[ "${DOWNLOAD_SUCCESS}" != "true" ]]; then
        echo -e "${RED}[错误] 核心压缩包拉取失败！由于您的 NAT 机器网络到 GitHub 存在延迟或阻断，请检查网络或更换节点重试。${PLAIN}"
        exit 1
    fi

    unzip -q -o XrayR.zip
    rm -f XrayR.zip
    chmod +x XrayR
    
    # 【NAT 特化校验】：硬检查解压出的文件是否为真正的 ELF 可执行文件（防止因网络代理返回 HTML 报错页导致误判）
    type_effect "${BLUE}➜ 正在进行 NAT 环境 ELF 二进制主程序严格审查...${PLAIN}"
    if [[ ! -f "XrayR" ]]; then
        echo -e "${RED}[严重错误] 未找到解压后的主程序文件！${PLAIN}"
        exit 1
    fi
    
    # 兼容性检查：若系统无 file 命令则通过 readelf 或直接尝试运行判断
    if command -v file >/dev/null 2>&1; then
        if ! file XrayR | grep -qE "ELF|executable"; then
            echo -e "${RED}[严重错误] 下载的文件不是合法的 Linux 可执行程序！${PLAIN}"
            echo -e "${YELLOW}提示：这通常是由于 NAT 机器网络链路异常，导致下载到了代理服务器的 HTML 错误页面。请稍后重试。${PLAIN}"
            cd .. && rm -rf ${INSTALL_DIR}
            exit 1
        fi
    fi

    type_effect "${BLUE}➜ 正在执行底层兼容性自检...${PLAIN}"
    if ! ./XrayR --version >/dev/null 2>&1 && ! ./XrayR -version >/dev/null 2>&1; then
        echo -e "${RED}[严重错误] 核心程序自检不通过！${PLAIN}"
        echo -e "${YELLOW}排查建议：部分极简 NAT 容器（如 Alpine/OpenVZ）可能缺少 glibc 运行库，建议检查系统架构或更换主流 Debian/Ubuntu 系统。${PLAIN}"
        cd .. && rm -rf ${INSTALL_DIR}
        exit 1
    fi
    type_effect "${GREEN}✔ 二进制自检通过！内核兼容性完美。${PLAIN}"

    if [ -f "${BACKUP_CONFIG}" ]; then
        mv -f ${BACKUP_CONFIG} ${INSTALL_DIR}/config.yml
        type_effect "${GREEN}✔ 历史对接参数已还原。${PLAIN}"
    fi
    [[ -f "${INSTALL_DIR}/config.yml" ]] && chmod 600 ${INSTALL_DIR}/config.yml

    type_effect "${YELLOW}\n[4/4] ⚙️ 正在向 [${INIT_SYSTEM^^}] 守护进程注册标准常驻服务...${PLAIN}"
    
    if [[ "$INIT_SYSTEM" == "systemd" ]]; then
        cat > /etc/systemd/system/xrayr.service <<EOF
[Unit]
Description=XrayR Backend Service (NAT Edition)
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/XrayR --config ${INSTALL_DIR}/config.yml
Restart=on-failure
RestartSec=10s
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
    else
        cat > /etc/init.d/xrayr <<'EOF'
#!/sbin/openrc-run
name="XrayR Backend Service"
description="XrayR Backend Service (NAT Edition)"
command="/etc/XrayR/XrayR"
command_args="--config /etc/XrayR/config.yml"
command_background="yes"
pidfile="/run/xrayr.pid"
output_log="/var/log/xrayr.log"
error_log="/var/log/xrayr.err"

depend() {
    need net
    use dns
}
EOF
        chmod +x /etc/init.d/xrayr
    fi

    srv_enable
    
    type_effect "${YELLOW}正在绑定系统快捷管理指令...${PLAIN}"
    if curl -sL --connect-timeout 15 "https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/main/install.sh" | sed 's/\r$//' > "/tmp/xrayr_temp.sh"; then
        if [[ -s "/tmp/xrayr_temp.sh" ]]; then
            mv -f "/tmp/xrayr_temp.sh" ${SYSTEM_CMD_PATH}
            chmod +x ${SYSTEM_CMD_PATH}
            ln -sf ${SYSTEM_CMD_PATH} /usr/local/bin/XrayR >/dev/null 2>&1
        fi
    fi
    rm -f "/tmp/xrayr_temp.sh" "${BACKUP_CONFIG}"

    type_effect "${GREEN}✔ 开机自启常驻与系统快捷指令 [xrayr / XrayR] 绑定成功。${PLAIN}"
    echo ""
    show_line
    echo -e " 🎉 ${BOLD}恭喜您！XrayR NAT 特化版本安装与加固完备！${PLAIN}"
    echo -e " ⚡ ${BLUE}终端随时输入指令: ${YELLOW}xrayr${BLUE} 或是 ${YELLOW}XrayR${BLUE} 即可呼出管理面板。${PLAIN}"
    show_line
    echo ""
    read -p "是否现在立即进入控制面板菜单？(y/n) [默认: y]: " choice
    if [[ -z "${choice}" || "${choice}" =~ ^[Yy]$ ]]; then
        show_manage_menu
    else
        exit 0
    fi
}

# 彻底卸载核心逻辑
uninstall_xrayr() {
    show_banner
    echo -e "${RED}[警告] 您正在执行卸载操作，这将物理清除所有程序文件与配置！${PLAIN}"
    read -p "确认要彻底卸载 XrayR 吗？(y/n): " un_choice
    if [[ "${un_choice:-}" =~ ^[Yy]$ ]]; then
        type_effect "${YELLOW}正在停止并注销常驻服务...${PLAIN}"
        srv_stop
        srv_disable
        
        if [[ "$INIT_SYSTEM" == "systemd" ]]; then
            rm -f /etc/systemd/system/xrayr.service
            systemctl daemon-reload >/dev/null 2>&1
        else
            rm -f /etc/init.d/xrayr
            rm -f /var/log/xrayr.log /var/log/xrayr.err
        fi
        
        type_effect "${YELLOW}正在深度物理擦除运行目录与环境变量...${PLAIN}"
        rm -rf ${INSTALL_DIR}
        rm -f ${SYSTEM_CMD_PATH}
        rm -f /usr/local/bin/XrayR
        
        type_effect "${GREEN}\n🎉 卸载成功！所有 XrayR 相关资产已彻底从系统卸载干净。${PLAIN}"
        exit 0
    else
        echo -e "${GREEN}已取消卸载流程。${PLAIN}"
        sleep 1.5
    fi
}

# 交互式快捷控制面板菜单
show_manage_menu() {
    while true; do
        show_banner
        
        if srv_is_active; then
            echo -e " 🟢 后端实时运行状态: ${GREEN}正在高能运行 (Running) [${INIT_SYSTEM^^}]${PLAIN}"
        else
            echo -e " 🔴 后端实时运行状态: ${RED}已安全停止 (Stopped) [${INIT_SYSTEM^^}]${PLAIN}"
        fi
        show_line
        
        echo -e "  ${GREEN}1.${PLAIN} 🚀 启动 XrayR 服务"
        echo -e "  ${GREEN}2.${PLAIN} 🛑 停止 XrayR 服务"
        echo -e "  ${GREEN}3.${PLAIN} 🔄 重启 XrayR 服务"
        echo -e " ---------------------------------"
        echo -e "  ${GREEN}4.${PLAIN} 📊 查看 实时运行状态 (Status)"
        echo -e "  ${GREEN}5.${PLAIN} 📄 查看 高连通性底层日志 (Logs)"
        echo -e "  ${GREEN}6.${PLAIN} 📝 手动修改 核心配置文件 (config.yml)"
        echo -e " ---------------------------------"
        echo -e "  ${GREEN}7.${PLAIN} 🔐 设置 XrayR 开机自启"
        echo -e "  ${GREEN}8.${PLAIN} 🔓 取消 XrayR 开机自启"
        echo -e " ---------------------------------"
        echo -e "  ${YELLOW}9.${PLAIN} ✨ 检查并极速覆盖更新 XrayR"
        echo -e "  ${RED}10.${PLAIN} 🗑️  彻底卸载 XrayR (物理擦除)"
        echo -e " ---------------------------------"
        echo -e "  ${RED}0.${PLAIN} ❌ 退出控制面板"
        show_line
        echo ""
        read -p " 请输入数字选择对应操作 [0-10]: " menu_num
        
        case "${menu_num:-}" in
            1)
                srv_start
                echo -e "${GREEN}启动指令已发出。${PLAIN}"
                sleep 1.5
                ;;
            2)
                srv_stop
                echo -e "${GREEN}停止指令已发出。${PLAIN}"
                sleep 1.5
                ;;
            3)
                srv_restart
                echo -e "${GREEN}重启指令已发出。${PLAIN}"
                sleep 1.5
                ;;
            4)
                echo -e "${YELLOW}正在获取系统级 Service 详细状态 (按 q 键退出查看)：${PLAIN}"
                echo "------------------------------------------------------------"
                srv_status
                echo "------------------------------------------------------------"
                read -p "按回车键返回主菜单..."
                ;;
            5)
                echo -e "${YELLOW}正在追踪实时运行日志：${PLAIN}"
                echo "------------------------------------------------------------"
                srv_logs
                ;;
            6)
                if [ -f "${INSTALL_DIR}/config.yml" ]; then
                    if command -v nano >/dev/null 2>&1; then
                        nano ${INSTALL_DIR}/config.yml
                    else
                        vi ${INSTALL_DIR}/config.yml
                    fi
                    echo -e "${YELLOW}配置已更改，正在自动平滑重启服务...${PLAIN}"
                    srv_restart
                    echo -e "${GREEN}服务重启完毕！${PLAIN}"
                else
                    echo -e "${RED}[错误] 配置文件不存在！${PLAIN}"
                fi
                sleep 2
                ;;
            7)
                srv_enable
                echo -e "${GREEN}成功开启开机自启动！${PLAIN}"
                sleep 1.5
                ;;
            8)
                srv_disable
                echo -e "${YELLOW}已取消开机自启动！${PLAIN}"
                sleep 1.5
                ;;
            9)
                show_install_process
                exit 0
                ;;
            10)
                uninstall_xrayr
                ;;
            0)
                echo -e "${GREEN}感谢使用，再见！${PLAIN}"
                exit 0
                ;;
            *)
                echo -e "${RED}[警告] 输入错误，请输入 0-10 之间的数字！${PLAIN}"
                sleep 1.5
                ;;
        esac
    done
}

# 核心判断机制：环境嗅探装甲
SCRIPT_NAME=$(basename "$0")
if [[ "$SCRIPT_NAME" == "xrayr" || "$SCRIPT_NAME" == "XrayR" || "${1:-}" == "menu" ]]; then
    show_manage_menu
else
    if [[ -f "${SYSTEM_CMD_PATH}" && -d "${INSTALL_DIR}" ]]; then
        show_banner
        echo -e "${YELLOW}⚠️ 检测到您的服务器已安装 XrayR 核心程序！${PLAIN}"
        echo -e "${GREEN}为了防止您的配置文件和运行状态被意外覆盖，已自动拦截重复安装请求。${PLAIN}"
        echo -e "👉 如果您想管理节点或更新版本，请直接在终端随时输入命令: ${BOLD}xrayr${PLAIN}"
        echo ""
        read -p "是否现在直接进入控制面板？(y/n) [默认: y]: " enter_menu
        if [[ -z "${enter_menu}" || "${enter_menu}" =~ ^[Yy]$ ]]; then
            show_manage_menu
        else
            echo -e "${GREEN}已安全退出。${PLAIN}"
            exit 0
        fi
    else
        show_install_process
    fi
fi
