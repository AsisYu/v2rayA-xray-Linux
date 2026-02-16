# 实施提案 - 修复 APT 镜像和文件匹配问题

## 需求描述

修复 setup.sh 中的两个问题：
1. 阿里云镜像源 URL 错误：`deb http://` 应该是 `http://`
2. 安装脚本中的文件名匹配可能不正确：当前文件名是 `installer_debian_x64_2.2.7.5.deb`（下划线），但匹配逻辑可能有问题

## 现状分析

### 问题 1：阿里云镜像 URL 错误

**错误日志**:
```
deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy main restricted universe multiverse
```

**正确 URL**:
```
http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy main restricted universe multiverse
```

### 问题 2：文件名匹配问题

**错误日志**:
```
[ERROR] 未找到 v2rayA 安装包 (installer_debian_*.deb)
```

**实际文件名**: `installer_debian_x64_v2.2.7.5.deb`

**当前匹配模式**: `^installer_debian_.*\.deb$`

这个模式理论上应该能匹配下划线。可能是其他原因导致匹配失败。

## 实施方案

### 修改点 1：修复阿里云镜像 URL

**位置**: setup.sh 第 290-296 行

**原代码**:
```bash
print_info "更新为阿里云镜像源..."
tee /etc/apt/sources.list <<-'EOF'
deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy main restricted universe multiverse
EOF
```

**修改为** (方法 1：heredoc 开头空行):
```bash
print_info "更新为阿里云镜像源..."
tee /etc/apt/sources.list <<-'EOF'

deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy main restricted universe multiverse
EOF
```

**修改为** (方法 2：使用 printf + cat 组合):
```bash
print_info "更新为阿里云镜像源..."
printf '%s\n' \
  "http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy main restricted universe multiverse\n" \
  "http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy-updates main restricted universe multiverse\n" \
  "http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy-backports main restricted universe multiverse\n" \
  "http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy-security main restricted universe multiverse\n" \
| tee /etc/apt/sources.list
```

**修改为** (方法 3：echo 多行 + tee):
```bash
print_info "更新为阿里云镜像源..."
{
  echo "deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy main restricted universe multiverse"
  echo "deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy-updates main restricted universe multiverse"
  echo "deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy-backports main restricted universe multiverse"
  echo "deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy-security main restricted universe multiverse"
} | tee /etc/apt/sources.list
```

### 修改点 2：增强文件名匹配逻辑

**位置**: setup.sh 第 306-313 行

**原代码**:
```bash
V2RAYA_DEB=$(ls -1 *.deb 2>/dev/null | grep -E "^installer_debian_.*\.deb$" | head -n 1)
if [ -z "$V2RAYA_DEB" ]; then
    print_error "未找到 v2rayA 安装包 (installer_debian_*.deb)"
    ls -la
    exit 1
fi
```

**修改为** (增强错误信息):
```bash
V2RAYA_DEB=$(ls -1 *.deb 2>/dev/null | grep -E "^installer_debian" | head -n 1)
if [ -z "$V2RAYA_DEB" ]; then
    print_error "未找到 v2rayA 安装包 (installer_debian_*.deb)"
    print_error "目录中的 .deb 文件:"
    ls -1 *.deb
    exit 1
fi
```

**修改为** (使用更宽松的匹配模式):
```bash
V2RAYA_DEB=$(ls -1 *.deb 2>/dev/null | grep -i "installer_debian" | head -n 1)
if [ -z "$V2RAYA_DEB" ]; then
    print_error "未找到 v2rayA 安装包 (installer_debian_*.deb)"
    print_error "目录中的 .deb 文件:"
    ls -1 *.deb
    exit 1
fi
```

## 实施清单

- [ ] 修复阿里云镜像 URL（heredoc 开头空行）
- [ ] 增强文件名匹配错误信息
- [ ] 本地测试验证修复效果
- [ ] 提交到 Git

## 回滚计划

如需回滚：
```bash
git checkout main -- setup.sh
```

## 影响评估

| 影响项 | 描述 |
|--------|------|
| 兼容性 | 向后兼容，仅修复 URL 和增强错误信息 |
| 用户体验 | 提升，修复 APT 更新失败和文件匹配问题 |
| 日志处理 | 改进，提供更清晰的错误信息 |

## 状态

- [x] 约束分析完成
- [x] 提案生成完成
- [x] 实施 setup.sh 修改
