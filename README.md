# XrayR - 2026 现代化重构版 (Codename: 将进酒)

<p align="center">
  <a href="https://github.com/Deeye/XrayR-AutoInstall/stargazers">
    <img src="https://img.shields.io/github/stars/Deeye/XrayR-AutoInstall?style=flat-square&logo=github&color=f1e05a" alt="Stars">
  </a>
  <a href="https://github.com/Deeye/XrayR-AutoInstall/network/members">
    <img src="https://img.shields.io/github/forks/Deeye/XrayR-AutoInstall?style=flat-square&logo=github&color=4183c4" alt="Forks">
  </a>
  <a href="https://github.com/Deeye/XrayR-AutoInstall/releases">
    <img src="https://img.shields.io/github/v/release/Deeye/XrayR-AutoInstall?style=flat-square&color=2ea44f" alt="Latest Release">
  </a>
  <a href="https://github.com/Deeye/XrayR-AutoInstall/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/Deeye/XrayR-AutoInstall?style=flat-square&color=blue" alt="License">
  </a>
</p>

> “君不见黄河之水天上来，奔流到海不复回。”

A Xray backend framework that can easily support many panels.
一个基于 Xray 的后端框架，支持 V2ray, Trojan, Shadowsocks 协议，极易扩展，支持多面板对接。

本项目基于原版 XrayR 底层架构进行深度重构与现代化精简。本版本的网络栈设计旨在让数据传输如黄河之水般奔流不息，特别针对现代云厂商的复杂 VPC 架构与 IPv6 双栈网络进行了严密的路由解耦。全面适配最新生态的 **V2board** / **Xboard** 体系，开箱即用。

如果您喜欢本项目，欢迎点个 Star 持续关注！

---

## 🚀 一键部署脚本 (强烈推荐)

在任何支持 Systemd 的 Linux 系统（Ubuntu / Debian / CentOS）上，直接复制并运行以下命令即可进入全自动纯净安装：

```bash
bash <(curl -Ls [https://raw.githubusercontent.com/Deeye/XrayR-AutoInstall/main/install.sh](https://raw.githubusercontent.com/Deeye/XrayR-AutoInstall/main/install.sh))


✨ 核心特性与功能
本项目不仅继承了原版强大的扩展能力，更在此基础上进行了深度现代化加固：

🟢 基础框架特性 (继承自原版)
多协议支持：全面支持 V2ray，Trojan，Shadowsocks 等主流协议。

新特性兼容：原生支持 Vless 和 XTLS 等高级防封锁特性。

多面板聚合：支持单实例对接多面板、多节点，无需重复运行多个服务端。

全面的流量管理：支持获取节点/用户信息、实时流量统计、在线人数上报，并支持限制违规在线 IP。

精准限速：支持节点端口级别、用户级别的精细化网络限速。

自动化运维：支持一键全自动申请与续签 TLS 证书，修改面板配置后后端自动平滑重启。

🚀 2026 独家重构优化
极简配置模板：彻底移除陈旧的历史包袱与冗余代码，原生提供基于 V2board/Xboard 的极简配置范本，大幅降低部署门槛。

双栈路由分离：在 custom_outbound 中原生实现 IPv4 / IPv6 显式双栈分流，彻底解决现代云原生环境下的寻址混乱与延迟突增问题。

DoH 强加密防污染：废弃传统 UDP 53 明文解析，内置 Cloudflare & Google 的 https+local:// 顶级加密 DNS 解析链路，突破严苛的网络审查。

底层安全加固：内置标准的黑洞（Blackhole）拦截器与针对 BitTorrent / P2P 协议的严格审计规则，极大降低 IDC 服务商版权投诉封机风险。

💻 支持前端面板
强烈推荐使用最新版架构的面版体系以获得最佳体验：

V2board / Xboard (默认完美兼容)

PPanel (兼容 PMPanel 等衍生版本)

sspanel-uim

ProxyPanel

GoV2Panel

BunPanel

⚠️ 免责声明
原作者免责：本项目属于基于原版代码的社区独立分支维护版本，仅供计算机网络学习、交流与技术研究使用。与原官方开发团队无任何直接关联。因使用本分支版本产生的任何软硬件故障、数据丢失或法律纠纷，原官方作者不承担任何连带责任。

维护者免责：本项目（包括但不限于修改后的配置文件、基础路由策略及编译打包的二进制程序）永久开源且免费，按“原样”提供，不提供任何形式的明示或暗示担保。使用者需自行承担服务器部署、节点引流与后续使用的所有风险。

合规使用：使用者必须自行遵守所在国家和地区的法律法规，以及所使用云服务商的最终用户许可协议（AUP/TOS）。严禁将本项目用于任何非法用途，任何违规行为造成的后果由使用者自行承担。

📄 许可证协议
本项目核心代码基于原作者的 Mozilla Public License Version 2.0 开源。配置文件与部署架构由社区重构维护。
