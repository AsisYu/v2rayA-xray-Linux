# 实施提案 - 修复 URL 构造错误

## 需求描述

修复 setup.sh 中的 URL 构造错误问题：print_info 输出被混入 URL 变量中，导致下载失败。

## 现状分析

### 错误现象

```
[ERROR] 下载 v2rayA 失败
[ERROR] URL: https://github.com/v2rayA/v2rayA/releases/download/[INFO] 正在获取 v2rayA 最新版本...
[INFO] v2rayA 最新版本: v2.2.7.5
v2.2.7.5/installer_debian_x64_[INFO] 正在获取 v2rayA 最新版本...
[INFO] v2rayA 最新版本: v2.2.7.5
v2.2.7.5.deb
```

### 正确期望

```
[INFO] v2rayA 最新版本: v2.2.7.5
[INFO] Xray-core 最新版本: v26.2.6
[INFO] 正在下载 v2rayA...
```

URL: `https://github.com/v2rayA/v2rayA/releases/download/v2.2.7.5/installer_debian_x64_v2.2.7.5.deb`

## 实施方案

### 修改点：重定向 print 函数输出到 stderr

**原代码** (第 44-54 行):
```bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}
```

**修改为**:
```bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}
```

### 修改说明

所有 `print_*` 函数添加 `>&2` 重定向到标准错误输出，避免日志输出混入变量赋值或后续命令的参数中。

## 实施清单

- [ ] 修改 print_info 函数添加 `>&2`
- [ ] 修改 print_error 函数添加 `>&2`
- [ ] 修改 print_warning 函数添加 `>&2`
- [ ] 本地测试验证 URL 构造正确
- [ ] 提交修改到 Git

## 回滚计划

如需回滚：
```bash
git checkout main -- setup.sh
```

## 影响评估

| 影响项 | 描述 |
|--------|------|
| 兼容性 | 向后兼容，仅改变输出目标 |
| 用户体验 | 提升，修复下载失败问题 |
| 日志处理 | 改进，日志输出到 stderr |

## 状态

- [x] 约束分析完成
- [x] 提案生成完成
- [x] 实施 setup.sh 修改
