# 约束集合 - 修复 APT 镜像和文件匹配问题

## 需求摘要

修复 setup.sh 中的两个问题：
1. 阿里云镜像源 URL 拼写错误（deb http://）
2. 安装脚本中的文件名匹配可能不正确

## 硬约束

| ID | 约束描述 | 来源 |
|----|---------|------|
| C1 | 修复阿里云镜像 URL | 用户错误日志 |
| C2 | 确保文件名匹配正确 | 用户错误日志 |
| C3 | 不修改原有功能逻辑 | 向后兼容 |

## 软约束

| ID | 约束描述 | 来源 |
|----|---------|------|
| S1 | 使用更宽松的匹配模式 | 提高匹配成功率 |

## 问题 1：阿里云镜像 URL 错误

### 错误日志
```
deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy main restricted universe multiverse
```

### 根本原因
heredoc 写入时，URL 格式错误：
```bash
tee /etc/apt/sources.list <<-'EOF'
deb http://mirrors.cloud.aliyuncs.com/...
EOF
```

`'EOF'` 中的第一行会作为 heredoc 的内容，导致 `deb ` 前缀被写入文件。

### 修复方案
**方法 1**：在 heredoc 内容开始处添加空行
```bash
tee /etc/apt/sources.list <<-'EOF'

deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy main restricted universe multiverse
EOF
```

**方法 2**：使用 printf + cat 组合（更可靠）
```bash
printf '%s\n' \
  "deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy main restricted universe multiverse\n" \
  "deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy-updates main restricted universe multiverse\n" \
  "deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy-backports main restricted universe multiverse\n" \
  "deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy-security main restricted universe multiverse\n" \
| tee /etc/apt/sources.list
```

## 问题 2：文件名匹配问题

### 错误日志
```
[ERROR] 未找到 v2rayA 安装包 (installer_debian_*.deb)
```

### 可能原因
当前匹配模式：`^installer_debian_.*\.deb$`
实际文件名：`installer_debian_x64_v2.2.7.5.deb`

这个模式理论上应该能匹配下划线。可能是其他原因：
1. 临时目录中的文件被清理了
2. 文件名确实不匹配

### 修复方案
**方法 1**：使用更宽松的匹配模式
```bash
V2RAYA_DEB=$(ls -1 *.deb 2>/dev/null | head -n 1)
```

**方法 2**：直接使用从 API 获取的文件名
```bash
# 在主流程中保存文件名
V2RAYA_DEB="installer_debian_x64_${V2RAYA_VERSION}.deb"

# 在生成安装脚本时使用
V2RAYA_DEB="installer_debian_x64_${V2RAYA_VERSION}.deb"
```

**方法 3**：增强错误信息，显示实际文件列表
```bash
V2RAYA_DEB=$(ls -1 *.deb 2>/dev/null | grep -E "^installer_debian" | head -n 1)
if [ -z "$V2RAYA_DEB" ]; then
    print_error "未找到 v2rayA 安装包"
    print_error "目录中的 .deb 文件:"
    ls -la *.deb 2>&1
    exit 1
fi
```

## 实施清单

- [ ] 修复阿里云镜像 URL 错误（heredoc 开头空行）
- [ ] 修复文件名匹配逻辑（使用宽松匹配或增强错误信息）
- [ ] 测试验证修复效果
- [ ] 提交到 Git

## 风险

| ID | 风险描述 | 缓解措施 |
|----|---------|------|
| R1 | printf 方式可能不兼容某些 shell | heredoc 方案更安全 |
| R2 | 文件名匹配逻辑可能有其他边界情况 | 添加文件列表显示 |

## 成功判据

| 判据 | 验证方式 | 期望结果 |
|------|---------|---------|
| SC1 | apt update 成功 | 无连接失败错误 |
| SC2 | 文件名正确匹配 | ls 命令找到 .deb 文件 |
| SC3 | dpkg 安装成功 | 安装无错误 |
