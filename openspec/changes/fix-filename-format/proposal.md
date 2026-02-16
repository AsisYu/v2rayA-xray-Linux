# 实施提案 - 修复文件名格式

## 需求描述

修复 setup.sh 中的 v2rayA 文件名构造错误：使用 `_v` 分隔符导致文件名不匹配，下载失败。

## 现状分析

### 错误日志

```
[ERROR] 下载 v2rayA 失败
[ERROR] URL: https://github.com/v2rayA/v2rayA/releases/download/v2.2.7.5/installer_debian_x64_v2.2.7.5.deb
```

### 实际文件名

GitHub API 返回的文件名：
```
installer_debian_x64_2.2.7.5.deb
```

### 根本原因

v2rayA 文件名格式从 `_v` 改为 `_`，但脚本仍使用旧格式：
- 旧格式：`installer_debian_x64_v2.2.7.5.deb`
- 新格式：`installer_debian_x64_2.2.7.5.deb`（下划线而非 `_v`）

## 实施方案

### 修改点 1：获取实际文件名

修改 `get_latest_version` 函数，同时返回版本号和文件名：

```bash
get_latest_version() {
    local repo=$1
    local name=$2
    local version
    local filename

    print_info "正在获取 $name 最新版本..."

    version=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name')

    if [ -z "$version" ] || [ "$version" = "null" ]; then
        print_error "无法获取 $name 的最新版本号"
        print_error "请检查网络连接或稍后重试"
        exit 1
    fi

    print_info "$name 最新版本: $version"

    # 获取对应架构的文件名
    if [ "$name" = "v2rayA" ]; then
        filename=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | jq -r ".assets[] | select(.name | contains(\"${V2RAYA_ARCH}\") and contains(\".deb\")) | .name")
        if [ -z "$filename" ]; then
            print_error "无法找到 $name 的 ${V2RAYA_ARCH} .deb 文件"
            exit 1
        fi
    else
        filename=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | jq -r ".assets[] | select(.name == \"Xray-linux-${XRAY_ARCH}.zip\") | .name")
        if [ -z "$filename" ]; then
            print_error "无法找到 $name 的 ${XRAY_ARCH} .zip 文件"
            exit 1
        fi
    fi

    # 输出版本号和文件名
    echo "$version"
    echo "$filename"
}
```

### 修改点 2：更新主流程

**原代码** (第 165-173 行):
```bash
# 获取最新版本
V2RAYA_VERSION=$(get_latest_version "$V2RAYA_REPO" "v2rayA")
XRAY_VERSION=$(get_latest_version "$XRAY_REPO" "Xray-core")

# 构造文件名和下载 URL
V2RAYA_DEB="installer_debian_${V2RAYA_ARCH}_${V2RAYA_VERSION}.deb"
V2RAYA_URL="https://github.com/${V2RAYA_REPO}/releases/download/${V2RAYA_VERSION}/${V2RAYA_DEB}"

XRAY_ZIP="Xray-linux-${XRAY_ARCH}.zip"
XRAY_URL="https://github.com/${XRAY_REPO}/releases/download/${XRAY_VERSION}/${XRAY_ZIP}"
```

**修改为**:
```bash
# 获取最新版本和文件名
V2RAYA_INFO=$(get_latest_version "$V2RAYA_REPO" "v2rayA")
V2RAYA_VERSION=$(echo "$V2RAYA_INFO" | head -1)
V2RAYA_DEB=$(echo "$V2RAYA_INFO" | tail -1)

XRAY_INFO=$(get_latest_version "$XRAY_REPO" "Xray-core")
XRAY_VERSION=$(echo "$XRAY_INFO" | head -1)
XRAY_ZIP=$(echo "$XRAY_INFO" | tail -1)

# 构造下载 URL
V2RAYA_URL="https://github.com/${V2RAYA_REPO}/releases/download/${V2RAYA_VERSION}/${V2RAYA_DEB}"
XRAY_URL="https://github.com/${XRAY_REPO}/releases/download/${XRAY_VERSION}/${XRAY_ZIP}"
```

## 实施清单

- [ ] 修改 get_latest_version 函数返回版本号和文件名
- [ ] 更新主流程使用 API 返回的文件名
- [ ] 测试验证文件名匹配
- [ ] 提交修改到 Git

## 回滚计划

如需回滚：
```bash
git checkout main -- setup.sh
```

## 影响评估

| 影响项 | 描述 |
|--------|------|
| 兼容性 | 向后兼容，修复文件名格式 |
| 用户体验 | 提升，修复下载失败问题 |
| API 调用 | 每个项目增加 1 次 API 调用 |

## 状态

- [x] 约束分析完成
- [x] 提案生成完成
- [ ] 实施 setup.sh 修改
