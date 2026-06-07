# Xboard-Node 多面板/多实例安装脚本 (Debian/Ubuntu)

<p align="center">
  <img src="https://img.shields.io/badge/Debian-Ubuntu-red?style=flat-square&logo=debian" alt="Debian/Ubuntu">
  <img src="https://img.shields.io/github/v/release/lei33440/xboard-node-multi-panel-debian?style=flat-square" alt="Version">
  <img src="https://img.shields.io/github/stars/lei33440/xboard-node-multi-panel-debian?style=flat-square" alt="Stars">
</p>

一个专为 **Debian/Ubuntu** 系统设计的 Xboard-Node **多面板/多实例** 一键安装脚本，支持在同一台服务器上对接多个面板。

> 💡 如果你只需要对接**单个面板**，请使用官方安装脚本：
> ```bash
> curl -fsSL https://raw.githubusercontent.com/cedar2025/xboard-node/dev/install.sh | sudo bash -s -- \
>   --mode machine --panel URL --token TOKEN --machine-id ID
> ```

## 功能特性

- ✅ **多面板支持** - 一台服务器对接多个不同面板
- ✅ **独立实例** - 每个实例独立运行，互不影响
- ✅ **独立管理** - 每个实例可单独启动/停止/查看日志
- ✅ **一键部署** - 只需一条命令即可完成安装
- ✅ **自动端口分配** - 自动分配不同端口，避免冲突
- ✅ **多架构支持** - 支持 amd64 和 arm64
- ✅ **systemd 管理** - 使用 systemd 服务管理

## 支持的系统

| 系统 | 架构 | 状态 |
|------|------|------|
| Debian 10+ | x86_64 (amd64) | ✅ 支持 |
| Debian 10+ | aarch64 (arm64) | ✅ 支持 |
| Ubuntu 18.04+ | x86_64 (amd64) | ✅ 支持 |
| Ubuntu 18.04+ | aarch64 (arm64) | ✅ 支持 |

## 快速开始

### 添加新实例（面板）

```bash
# 添加第一个面板
curl -fsSL https://raw.githubusercontent.com/lei33440/xboard-node-multi-panel-debian/main/install-instance.sh | sudo bash -s -- \
  --name mypanel \
  --panel http://面板1地址 \
  --token 面板1TOKEN \
  --machine-id 1

# 添加第二个面板
curl -fsSL https://raw.githubusercontent.com/lei33440/xboard-node-multi-panel-debian/main/install-instance.sh | sudo bash -s -- \
  --name backup \
  --panel http://面板2地址 \
  --token 面板2TOKEN \
  --machine-id 1
```

### 参数说明

| 参数 | 必需 | 说明 |
|------|------|------|
| `--name` | 是 | 实例名称（英文，唯一标识） |
| `--panel` | 是 | 面板地址 URL |
| `--token` | 是 | 通信令牌 |
| `--machine-id` | 是 | 机器 ID |
| `--version` | 否 | Xboard-Node 版本（默认：latest） |
| `--help` | 否 | 显示帮助信息 |

## 实例管理

### 查看所有实例

```bash
# 查看 systemd 服务状态
systemctl status 'xboard-node-*'

# 查看进程
ps aux | grep xboard-node | grep -v grep

# 查看端口
ss -tlnp | grep xboard
```

### 启动/停止/重启单个实例

```bash
# 启动
sudo systemctl start xboard-node-mypanel

# 停止
sudo systemctl stop xboard-node-mypanel

# 重启
sudo systemctl restart xboard-node-mypanel

# 查看状态
sudo systemctl status xboard-node-mypanel

# 查看日志
sudo journalctl -u xboard-node-mypanel -f
```

### 重启所有实例

```bash
# 停止所有
sudo systemctl stop 'xboard-node-*'

# 启动所有
sudo systemctl start 'xboard-node-*'

# 或者使用脚本
sudo /usr/local/bin/xboard-node-start-all
```

### 卸载实例

```bash
# 卸载指定实例
curl -fsSL https://raw.githubusercontent.com/lei33440/xboard-node-multi-panel-debian/main/uninstall-instance.sh | sudo bash -s -- --name mypanel

# 卸载所有实例
curl -fsSL https://raw.githubusercontent.com/lei33440/xboard-node-multi-panel-debian/main/uninstall-all.sh | sudo bash
```

## 文件位置

| 文件 | 路径 |
|------|------|
| 二进制 | `/usr/local/bin/xboard-node` |
| 实例配置 | `/etc/xboard-node-{实例名}/config.yml` |
| systemd 服务 | `/etc/systemd/system/xboard-node-{实例名}.service` |
| 统一启动脚本 | `/usr/local/bin/xboard-node-start-all` |

## 常见问题

### Q: 实例名称有什么要求？

A: 只能是英文字母、数字和连字符，不能有特殊字符。例如：`mypanel`、`panel-1`、`backup`。

### Q: 如何确认实例正常运行？

A: 查看服务状态和端口：
```bash
systemctl status xboard-node-mypanel
ss -tlnp | grep xboard
```

### Q: 可以同时运行多少个实例？

A: 理论上没有限制，但受服务器性能和端口数量限制。建议不超过 10 个实例。

### Q: 如何备份配置？

A:
```bash
# 备份所有实例配置
sudo tar -czf xboard-node-backup.tar.gz /etc/xboard-node-* /var/log/xboard-node-*.log

# 恢复备份
sudo tar -xzf xboard-node-backup.tar.gz -C /
```

### Q: 日志在哪里查看？

A: 使用 journalctl 查看 systemd 日志：
```bash
sudo journalctl -u xboard-node-mypanel -f
```

## 更新日志

### v1.0.0 (2026-06-07)
- 🎉 首发版本
- ✅ 支持多面板/多实例
- ✅ 独立 systemd 服务管理
- ✅ 支持 amd64 和 arm64 架构
- ✅ 支持开机自启

## 相关项目

- [xboard-node-alpine-install](https://github.com/lei33440/xboard-node-alpine-install) - Alpine Linux 单面板安装
- [xboard-node-multi-panel](https://github.com/lei33440/xboard-node-multi-panel) - Alpine Linux 多面板安装
- [Xboard](https://github.com/cedar2025/Xboard) - 功能强大的代理面板
- [Xboard-Node](https://github.com/cedar2025/Xboard-Node) - Xboard 节点后端

## 许可证

本项目基于 MPL-2.0 许可证开源。

## 联系方式

- GitHub: https://github.com/lei33440
- 项目反馈: https://github.com/lei33440/xboard-node-multi-panel-debian/issues