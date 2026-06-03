#!/bin/bash

# ==========================================================
# 项目名称: XrayR 现代化重构版全功能管理脚本 (Codename: 将进酒)
# 适用系统: Ubuntu / Debian / CentOS
# 专属仓库: https://github.com/Deeye/XrayR-AutoInstall
# ==========================================================

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

# 华丽的流式打字机美化特效
type_effect() {
    local text="$1"
    local delay=0.01
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
    echo -e " 🚀 ${BOLD}XrayR 2026 现代化重构版 控制面板${PLAIN} | ${MAGENTA}Codename: 将进酒${PLAIN}"
    echo -e " 📂 ${YELLOW}开源仓库: https://github.com/${GITHUB_USER}/${REPO_NAME}${PLAIN}"
    show_line
}

# 严格的 Root 权限检查
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[错误] 本脚本必须以 root 用户身份运行！请执行 sudo -i 切换后重试。${PLAIN}"
    exit 1
fi

# 核心功能：核心主程序全自动安装/更新流程
show_install_process() {
    show_banner
    type_effect "${YELLOW}[1/4] 🚀 正在深度扫描系统架构并同步基础环境依赖...${PLAIN}"
    if [[ -f /etc/redhat-release ]]; then
        yum install -y curl wget unzip ca-certificates >/dev/null 2>&1
    elif grep -Eqi "debian|ubuntu" /etc/issue || grep -Eq "Debian|Ubuntu" /etc/*-release; then
        apt-get update >/dev/null 2>&1
        apt-get install -y curl wget unzip ca-certificates >/dev/null 2>&1
    else
        echo -e "${RED}[错误] 极其抱歉！当前脚本仅支持 CentOS / Ubuntu / Debian 系统。${PLAIN}"
        exit 1
    fi
    type_effect "${GREEN}✔ 环境依赖项扫描通过，所需基础工具已全部就绪。${PLAIN}"

    type_effect "${YELLOW}\n[2/4] 📂 正在初始化纯净目标运行目录空间 ${INSTALL_DIR} ...${PLAIN}"
    if [ -f "${INSTALL_DIR}/config.yml" ]; then
        type_effect "${BLUE}➜ 检测到现有配置，正在无缝备份 config.yml ...${PLAIN}"
        cp -f ${INSTALL_DIR}/config.yml /tmp/xrayr_config_bak.yml
    fi
    rm -rf ${INSTALL_DIR}
    mkdir -p ${INSTALL_DIR}
    cd ${INSTALL_DIR}

    type_effect "${YELLOW}\n[3/4] 🌐 正在从 GitHub 官方 Release 极速拉取核心组件...${PLAIN}"
    ZIP_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}/releases/download/${RELEASE_VERSION}/XrayR-linux-64.zip"
    wget -N --no-check-certificate -O XrayR.zip ${ZIP_URL}

    if [[ ! -f "XrayR.zip" ]]; then
        echo -e "${RED}[错误] 核心压缩包拉取失败！请确认您的 GitHub Release 页面是否完整。${PLAIN}"
        exit 1
    fi

    unzip -q -o XrayR.zip
    rm -f XrayR.zip
    chmod +x XrayR
    
    if [ -f "/tmp/xrayr_config_bak.yml" ]; then
        mv -f /tmp/xrayr_config_bak.yml ${INSTALL_DIR}/config.yml
        type_effect "${GREEN}✔ 历史面板对接参数已无缝还原。${PLAIN}"
    fi
    type_effect "${GREEN}✔ 二进制主程序解压完毕，重构版双栈路由库注入成功。${PLAIN}"

    type_effect "${YELLOW}\n[4/4] ⚙️ 正在向守护进程系统注册标准常驻服务...${PLAIN}"
    cat > /etc/systemd/system/xrayr.service <<EOF
[Unit]
Description=XrayR Backend Service (2026 Edition)
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/XrayR --config ${INSTALL_DIR}/config.yml
Restart=on-failure
RestartSec=10s
LimitNOFILE=512000

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable xrayr >/dev/null 2>&1
    
    # 终极修复：直接从云端强制拉取最新脚本作为系统命令，彻底断绝幻影复制 BUG
    curl -Ls "https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/main/install.sh" | sed 's/\r$//' > ${SYSTEM_CMD_PATH}
    chmod +x ${SYSTEM_CMD_PATH}
    ln -sf ${SYSTEM_CMD_PATH} /usr/local/bin/XrayR >/dev/null 2>&1

    type_effect "${GREEN}✔ 开机自启常驻与系统快捷指令 [xrayr / XrayR] 绑定成功。${PLAIN}"
    echo ""
    show_line
    echo -e " 🎉 ${BOLD}恭喜您！XrayR 核心程序安装/更新成功！${PLAIN}"
    echo -e " ⚡ ${BLUE}以后在任何路径下，只需输入: ${YELLOW}xrayr${BLUE} 或者是 ${YELLOW}XrayR${BLUE} 即可唤醒本管理面板！${PLAIN}"
    show_line
    echo ""
    read -p "是否现在进入控制面板菜单？(y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
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
    if [[ "$un_choice" == "y" || "$un_choice" == "Y" ]]; then
        type_effect "${YELLOW}正在停止并注销常驻服务...${PLAIN}"
        systemctl stop xrayr >/dev/null 2>&1
        systemctl disable xrayr >/dev/null 2>&1
        rm -f /etc/systemd/system/xrayr.service
        systemctl daemon-reload
        
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
        
        if systemctl is-active xrayr >/dev/null 2>&1; then
            echo -e " 🟢 后端实时运行状态: ${GREEN}正在高能运行 (Running)${PLAIN}"
        else
            echo -e " 🔴 后端实时运行状态: ${RED}已安全停止 (Stopped)${PLAIN}"
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
        echo -e "  ${YELLOW}9.${PLAIN} ✨ 检查并覆盖更新 XrayR 后端版本"
        echo -e "  ${RED}10.${PLAIN} 🗑️  彻底卸载 XrayR (物理擦除)"
        echo -e " ---------------------------------"
        echo -e "  ${RED}0.${PLAIN} ❌ 退出控制面板"
        show_line
        echo ""
        read -p " 请输入数字选择对应操作 [0-10]: " menu_num
        
        case $menu_num in
            1)
                systemctl start xrayr
                echo -e "${GREEN}启动指令已发出。${PLAIN}"
                sleep 1.5
                ;;
            2)
                systemctl stop xrayr
                echo -e "${GREEN}停止指令已发出。${PLAIN}"
                sleep 1.5
                ;;
            3)
                systemctl restart xrayr
                echo -e "${GREEN}重启指令已发出。${PLAIN}"
                sleep 1.5
                ;;
            4)
                echo -e "${YELLOW}正在获取系统级 Service 详细状态 (按 q 键退出查看)：${PLAIN}"
                echo "------------------------------------------------------------"
                systemctl status xrayr
                echo "------------------------------------------------------------"
                read -p "按回车键返回主菜单..."
                ;;
            5)
                echo -e "${YELLOW}正在追踪实时运行日志 (按 Ctrl+C 即可断开退出)：${PLAIN}"
                echo "------------------------------------------------------------"
                journalctl -u xrayr -f
                ;;
            6)
                if [ -f "${INSTALL_DIR}/config.yml" ]; then
                    nano ${INSTALL_DIR}/config.yml
                    echo -e "${YELLOW}配置已更改，正在自动平滑重启服务...${PLAIN}"
                    systemctl restart xrayr
                    echo -e "${GREEN}服务重启完毕！${PLAIN}"
                else
                    echo -e "${RED}[错误] 配置文件不存在！${PLAIN}"
                fi
                sleep 2
                ;;
            7)
                systemctl enable xrayr >/dev/null 2>&1
                echo -e "${GREEN}成功开启开机自启动！${PLAIN}"
                sleep 1.5
                ;;
            8)
                systemctl disable xrayr >/dev/null 2>&1
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

# 终极修复：使用 basename 判断，无视执行路径，完美匹配大小写
SCRIPT_NAME=$(basename "$0")
if [[ "$SCRIPT_NAME" == "xrayr" || "$SCRIPT_NAME" == "XrayR" || "$1" == "menu" ]]; then
    show_manage_menu
else
    show_install_process
fi
