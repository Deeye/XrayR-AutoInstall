#!/bin/bash

# ==========================================================
# 项目名称: XrayR 现代化重构版全功能管理脚本 (Codename: 将进酒)
# 适用系统: Ubuntu / Debian / CentOS
# 专属仓库: https://github.com/Deeye/XrayR-AutoInstall
# ==========================================================

# 字体颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

# 项目核心全局变量
GITHUB_USER="Deeye"
REPO_NAME="XrayR-AutoInstall"
RELEASE_VERSION="v1.0.0"
INSTALL_DIR="/etc/XrayR"
SYSTEM_CMD_PATH="/usr/local/bin/xrayr"

# 华丽的 LOGO Banner 函数
show_banner() {
    clear
    echo -e "${CYAN}==================================================================${PLAIN}"
    echo -e "${PURPLE}   _  __               ____   ____                                ${PLAIN}"
    echo -e "${PURPLE}  | |/ /_ __ __ _ _   _|  _ \ |  _ \                               ${PLAIN}"
    echo -e "${PURPLE}  | ' /| '__/ _\` | | | | |_) || |_) |                              ${PLAIN}"
    echo -e "${PURPLE}  | . \| | | (_| | |_| |  _ < |  _ <                               ${PLAIN}"
    echo -e "${PURPLE}  |_|\_\_|  \__,_|\__, |_| \_\|_| \_\                              ${PLAIN}"
    echo -e "${PURPLE}                  |___/                                            ${PLAIN}"
    echo -e "${CYAN}==================================================================${PLAIN}"
    echo -e " 🚀 ${GREEN}XrayR 2026 现代化重构版 控制面板 (Codename: 将进酒)${PLAIN}"
    echo -e " 📂 ${YELLOW}开源仓库: https://github.com/${GITHUB_USER}/${REPO_NAME}${PLAIN}"
    echo -e "${CYAN}==================================================================${PLAIN}"
}

# 严格的 Root 权限检查
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[错误] 本脚本必须以 root 用户身份运行！请执行 sudo -i 切换后重试。${PLAIN}"
    exit 1
fi

# 核心功能：核心主程序全自动安装/更新流程
show_install_process() {
    show_banner
    echo -e "${YELLOW}[1/4] 正在扫描系统架构并同步基础环境依赖...${PLAIN}"
    if [[ -f /etc/redhat-release ]]; then
        yum install -y curl wget unzip ca-certificates >/dev/null 2>&1
    elif grep -Eqi "debian|ubuntu" /etc/issue || grep -Eq "Debian|Ubuntu" /etc/*-release; then
        apt-get update >/dev/null 2>&1
        apt-get install -y curl wget unzip ca-certificates >/dev/null 2>&1
    else
        echo -e "${RED}[错误] 极其抱歉！当前脚本仅支持 CentOS / Ubuntu / Debian 系统。${PLAIN}"
        exit 1
    fi
    echo -e "${GREEN} -> 环境依赖项扫描通过，所需基础工具已准备就绪。${PLAIN}"

    echo -e "${YELLOW}\n[2/4] 正在初始化目标运行目录空间 ${INSTALL_DIR} ...${PLAIN}"
    # 如果是更新，保留原配置文件
    if [ -f "${INSTALL_DIR}/config.yml" ]; then
        echo -e "${BLUE} -> 检测到现有配置，正在备份 config.yml ...${PLAIN}"
        cp -f ${INSTALL_DIR}/config.yml /tmp/xrayr_config_bak.yml
    fi
    rm -rf ${INSTALL_DIR}
    mkdir -p ${INSTALL_DIR}
    cd ${INSTALL_DIR}

    echo -e "${YELLOW}\n[3/4] 正在从 GitHub 官方 Release 极速下载核心组件...${PLAIN}"
    ZIP_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}/releases/download/${RELEASE_VERSION}/XrayR-linux-64.zip"
    wget -N --no-check-certificate -O XrayR.zip ${ZIP_URL}

    if [[ ! -f "XrayR.zip" ]]; then
        echo -e "${RED}[错误] 核心压缩包拉取失败！请确认您的 GitHub Release 页面中是否正确包含了名为 XrayR-linux-64.zip 的附件。${PLAIN}"
        exit 1
    fi

    unzip -q -o XrayR.zip
    rm -f XrayR.zip
    chmod +x XrayR
    
    # 如果是更新，还原老配置文件
    if [ -f "/tmp/xrayr_config_bak.yml" ]; then
        mv -f /tmp/xrayr_config_bak.yml ${INSTALL_DIR}/config.yml
        echo -e "${GREEN} -> 历史面板对接参数已无缝还原。${PLAIN}"
    fi
    echo -e "${GREEN} -> 二进制主程序解压完毕，配置模板及最新路由库注入成功。${PLAIN}"

    echo -e "${YELLOW}\n[4/4] 正在向 Linux 系统注册标准守护进程服务...${PLAIN}"
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
    
    # 将自身脚本复制到系统环境变量中，并赋予快捷键
    cp -f "$0" ${SYSTEM_CMD_PATH} >/dev/null 2>&1
    chmod +x ${SYSTEM_CMD_PATH}
    ln -sf ${SYSTEM_CMD_PATH} /usr/local/bin/XrayR >/dev/null 2>&1

    echo -e "${GREEN} -> 开机自启常驻与系统快捷快捷指令 [xrayr] 绑定成功。${PLAIN}"
    echo ""
    echo -e "${GREEN}==================================================================${PLAIN}"
    echo -e " 🎉 ${GREEN}恭喜您！XrayR 核心程序安装/更新成功！${PLAIN}"
    echo -e " ⚙️  ${BLUE}以后在任何路径下，只需输入: ${YELLOW}xrayr${BLUE} 即可唤醒本管理面板！${PLAIN}"
    echo -e "${GREEN}==================================================================${PLAIN}"
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
    echo -e "${RED}[警告] 您正在执行卸载操作，这将清除所有程序文件、配置文件和环境变量！${PLAIN}"
    read -p "确认要彻底卸载 XrayR 吗？(y/n): " un_choice
    if [[ "$un_choice" == "y" || "$un_choice" == "Y" ]]; then
        echo -e "${YELLOW}正在停止并清理服务...${PLAIN}"
        systemctl stop xrayr >/dev/null 2>&1
        systemctl disable xrayr >/dev/null 2>&1
        rm -f /etc/systemd/system/xrayr.service
        systemctl daemon-reload
        
        echo -e "${YELLOW}正在物理擦除运行目录与系统环境变量...${PLAIN}"
        rm -rf ${INSTALL_DIR}
        rm -f ${SYSTEM_CMD_PATH}
        rm -f /usr/local/bin/XrayR
        
        echo -e "${GREEN}\n🎉 卸载成功！所有 XrayR 相关资产已从您的服务器中彻底净化销毁。${PLAIN}"
        exit 0
    else
        echo -e "${GREEN}已取消卸载流程。${PLAIN}"
        sleep 1.5
    fi
}

# 核心功能：交互式快捷控制面板菜单
show_manage_menu() {
    while true; do
        show_banner
        
        # 实时检测服务当前运行状态
        if systemctl is-active xrayr >/dev/null 2>&1; then
            echo -e " 🟢 当前后端运行状态: ${GREEN}正在运行 (Running)${PLAIN}"
        else
            echo -e " 🔴 当前后端运行状态: ${RED}已停止 (Stopped)${PLAIN}"
        fi
        echo -e "${CYAN}==================================================================${PLAIN}"
        
        # 菜单选项排版（全新黄金排版）
        echo -e "  ${GREEN}1.${PLAIN} 启动 XrayR 服务"
        echo -e "  ${GREEN}2.${PLAIN} 停止 XrayR 服务"
        echo -e "  ${GREEN}3.${PLAIN} 重启 XrayR 服务"
        echo -e " ---------------------------------"
        echo -e "  ${GREEN}4.${PLAIN} 查看 实时运行状态 (Status)"
        echo -e "  ${GREEN}5.${PLAIN} 查看 高连通性底层加密日志 (Logs)"
        echo -e "  ${GREEN}6.${PLAIN} 手动修改 核心配置文件 (config.yml)"
        echo -e " ---------------------------------"
        echo -e "  ${GREEN}7.${PLAIN} 设置 XrayR 开机自启"
        echo -e "  ${GREEN}8.${PLAIN} 取消 XrayR 开机自启"
        echo -e " ---------------------------------"
        echo -e "  ${YELLOW}9.${PLAIN} 检查并覆盖更新 XrayR 后端版本"
        echo -e "  ${RED}10.${PLAIN} 彻底卸载 XrayR (清除所有文件)"
        echo -e " ---------------------------------"
        echo -e "  ${RED}0.${PLAIN} 退出控制面板"
        echo -e "${CYAN}==================================================================${PLAIN}"
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
                echo -e "${YELLOW}正在追踪实时运行日志 (实时滚动中，按 Ctrl+C 即可断开退出)：${PLAIN}"
                echo "------------------------------------------------------------"
                journalctl -u xrayr -f
                ;;
            6)
                if [ -f "${INSTALL_DIR}/config.yml" ]; then
                    nano ${INSTALL_DIR}/config.yml
                    echo -e "${YELLOW}修改完成，正在自动重启服务使其生效...${PLAIN}"
                    systemctl restart xrayr
                    echo -e "${GREEN}服务重启完毕！${PLAIN}"
                else
                    echo -e "${RED}[错误] 找不到配置文件，请先执行安装！${PLAIN}"
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
                echo -e "${RED}[警告] 输入错误！请输入有效的数字序号 [0-10]${PLAIN}"
                sleep 1.5
                ;;
        esac
    done
}

# 判断是首次安装还是快捷命令唤醒
if [[ "$0" == "${SYSTEM_CMD_PATH}" || "$1" == "menu" ]]; then
    show_manage_menu
else
    show_install_process
fi
