# v2rayA-for-Linux

v2rayA + Xray 一键安装脚本。

## 快速安装

### 标准安装

```bash
curl -fsSL https://raw.githubusercontent.com/AsisYu/v2rayA-xray-Linux/main/setup.sh | sudo bash
```

### 国内服务器

**root 用户：**
```bash
curl -fsSL https://v6.gh-proxy.org/https://raw.githubusercontent.com/AsisYu/v2rayA-xray-Linux/main/setup.sh | env GITHUB_API_PROXY=https://api.github.com GITHUB_DOWNLOAD_PROXY=https://v6.gh-proxy.org bash
```

**非 root 用户：**
```bash
curl -fsSL https://v6.gh-proxy.org/https://raw.githubusercontent.com/AsisYu/v2rayA-xray-Linux/main/setup.sh | sudo env GITHUB_API_PROXY=https://api.github.com GITHUB_DOWNLOAD_PROXY=https://v6.gh-proxy.org bash
```

## 支持系统

Debian/Ubuntu, CentOS/RHEL, Rocky Linux, AlmaLinux, Fedora

## 安装后访问

```
http://localhost:2017
```

## 服务管理

```bash
systemctl start v2raya      # 启动
systemctl stop v2raya       # 停止
systemctl restart v2raya    # 重启
systemctl status v2raya     # 状态
```

## 卸载

```bash
sudo ./uninstall.sh           # 标准卸载
sudo ./uninstall.sh --purge   # 完全清理
```

## 相关链接

- v2rayA: https://github.com/v2rayA/v2rayA
- Xray-core: https://github.com/XTLS/Xray-core
