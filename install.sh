#!/bin/bash

# ==========================================================
# 项目名称: XrayR 现代化重构版纯净安装脚本 (Codename: 将进酒)
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

# 华丽的开场 Banner
clear
echo -e "${CYAN}==================================================================${PLAIN}"
echo -e "${PURPLE}   _  __               ____   ____                                ${PLAIN}"
echo -e "${PURPLE}  | |/ /_ __ __ _ _   _|  _ \ |  _ \                               ${PLAIN}"
echo -e "${PURPLE}  | ' /| '__/ _\` | | | | |_) || |_) |                              ${PLAIN}"
echo -e "${PURPLE}  | . \| | | (_| | |_| |  _ < |  _ <                               ${PLAIN}"
echo -e "${PURPLE}  |_|\_\_|  \__,_|\__, |_| \_\|_| \_\                              ${PLAIN}"
echo -e "${PURPLE}                  |___/                                            ${PLAIN}"
echo -e "${CYAN}==================================================================${PLAIN}"
echo -e " 🚀 ${GREEN}欢迎使用 XrayR 2026 现代化重构版一键纯净部署脚本${PLAIN}"
echo -e " 💎 ${BLUE}项目代号: Codename 将进酒${PLAIN}"
echo -e " 📂 ${YELLOW}开源仓库: https://github.com/${GITHUB_USER}/${REPO_NAME}${PLAIN}"
echo -e "${CYAN}==================================================================${PLAIN}"
echo ""

# 1. 严格的 Root 权限检查
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[错误] 本脚本必须以 root 用户身份运行！请执行 sudo -i 切换后重试。${PLAIN}"
    exit 1
fi

# 2. 系统兼容性与底层基础依赖检测
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

# 3. 干净利落地初始化目录空间
echo -e "${YELLOW}\n[2/4] 正在初始化目标运行目录空间 ${INSTALL_DIR} ...${PLAIN}"
rm -rf ${INSTALL_DIR}
mkdir -p ${INSTALL_DIR}
cd ${INSTALL_DIR}

# 4. 从你的专属 Release 页面拉取 2026 现代化核心组件
echo -e "${YELLOW}\n[3/4] 正在从 GitHub 官方 Release 极速下载核心组件...${PLAIN}"
ZIP_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}/releases/download/${RELEASE_VERSION}/XrayR-linux-64.zip"
wget -N --no-check-certificate -O XrayR.zip ${ZIP_URL}

if [[ ! -f "XrayR.zip" ]]; then
    echo -e "${RED}[错误] 核心压缩包拉取失败！请确认您的 GitHub Release 页面中是否正确包含了名为 XrayR-linux-64.zip 的附件。${PLAIN}"
    exit 1
fi

# 解压并净化运行空间
unzip -q -o XrayR.zip
rm -f XrayR.zip
chmod +x XrayR
echo -e "${GREEN} -> 二进制主程序解压完毕，配置模板及最新路由库注入成功。${PLAIN}"

# 5. 全自动注册系统级守护进程 (Systemd Service)
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
echo -e "${GREEN} -> 开机自启常驻与崩溃自愈系统构建成功。${PLAIN}"

# 完美的交付界面
echo ""
echo -e "${CYAN}==================================================================${PLAIN}"
echo -e " 🎉 ${GREEN}恭喜您！XrayR 纯净版程序及优化配置文件已全部安装完毕！${PLAIN}"
echo -e "${CYAN}==================================================================${PLAIN}"
echo -e " ⚙️  ${BLUE}运行根路径:${PLAIN}  ${YELLOW}${INSTALL_DIR}${PLAIN}"
echo -e " 📝 ${BLUE}核心配置文件:${PLAIN} ${YELLOW}${INSTALL_DIR}/config.yml${PLAIN}"
echo ""
echo -e " ⚠️  ${RED}请按照以下步骤手动完成后续对接：${PLAIN}"
echo -e "   1. 修改配置文件，填入您的面板参数："
echo -e "      ${GREEN}nano ${INSTALL_DIR}/config.yml${PLAIN}"
echo -e "   2. 确认配置无误后，手动启动服务："
echo -e "      ${GREEN}systemctl start xrayr${PLAIN}"
echo -e "   3. 查看运行状态："
echo -e "      ${GREEN}systemctl status xrayr${PLAIN}"
echo "------------------------------------------------------------------"
echo -e " 🛠️  ${CYAN}日常核心服务管理快捷指令：${PLAIN}"
echo -e "   👉 ${GREEN}systemctl restart xrayr${PLAIN} - 重启节点服务"
echo -e "   👉 ${GREEN}systemctl stop xrayr${PLAIN}    - 停止节点服务"
echo -e "   👉 ${GREEN}journalctl -u xrayr -f${PLAIN}   - 查看实时运行日志"
echo -e "${CYAN}==================================================================${PLAIN}"