# 约束集合 - 修复 URL 构造错误

## 需求摘要

修复 setup.sh 中的 URL 构造错误问题：print_info 输出被混入 URL 变量中，导致下载失败。

## 问题分析

### 错误日志

```
[ERROR] 下载 v2rayA 失败
[ERROR] URL: https://github.com/v2rayA/v2rayA/releases/download/[INFO] 正在获取 v2rayA 最新版本...
[INFO] v2rayA 最新版本: v2.2.7.5
v2.2.7.5/installer_debian_x64_[INFO] 正在获取 v2rayA 最新版本...
[INFO] v2rayA 最新版本: v2.2.7.5
v2.2.7.5.deb
```

### 正确的 URL

```
https://github.com/v2rayA/v2rayA/releases/download/v2.2.7.5/installer_debian_x64_v2.2.7.5.deb
```

### 根本原因

`print_info` 函数的输出被某种方式捕获或混入了后续的变量赋值中，导致：
- URL 中包含 `[INFO]` 标签
- 版本号被重复

## 硬约束

| ID | 约束描述 | 来源 |
|----|---------|------|
| C1 | 修复 URL 构造逻辑 | 用户明确要求 |
| C2 | 确保 print_info 输出不影响变量 | 隔离输出和变量赋值 |
| C3 | 保持其他功能不变 | 向后兼容 |

## 软约束

| ID | 约束描述 | 来源 |
|----|---------|------|
| S1 | 使用 stderr 输出日志，避免污染 stdout | 最佳实践 |
| S2 | 确保 version 变量只包含版本号 | 数据纯净性 |

## 修复方案

### 方案 1：重定向 print_info 到 stderr

修改 `print_info`、`print_error`、`print_warning` 函数，将输出重定向到 stderr：

```bash
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

### 方案 2：在版本获取后添加延迟

确保 print_info 输出完成后再进行变量赋值。

## 依赖关系

```
setup.sh 修改:
├── 修改 print_* 函数重定向到 stderr
└── 确保变量赋值不受输出影响
```

## 风险

| ID | 风险描述 | 缓解措施 |
|----|---------|---------|
| R1 | 输出重定向可能影响用户捕获日志 | stderr 适合日志输出 |

## 成功判据

| 判据 | 验证方式 | 期望结果 |
|------|---------|---------|
| SC1 | URL 正确构造 | grep "github.com/.*releases/download" |
| SC2 | 下载成功 | wget 无错误 |
| SC3 | 版本号正确 | URL 包含单一版本号 |

## 禁止事项

| ID | 禁止行为 | 原因 |
|----|---------|------|
| P1 | 修改下载 URL 逻辑 | 只修复输出问题 |
