#!/bin/bash

# v2rayA + Xray 一键安装引导脚本
# 用户通过 curl 执行此脚本，会自动从 GitHub 获取最新版本并安装

set -e

# ==================== 配置区域 ====================
# GitHub 仓库信息
V2RAYA_REPO="v2rayA/v2rayA"
XRAY_REPO="XTLS/Xray-core"

# 架构配置（默认 amd64，可自动检测）
ARCH="${ARCH:-amd64}"

# v2rayA Debian 架构映射
case "$ARCH" in
    amd64|x86_64) V2RAYA_ARCH="x64" ;;
    arm64|aarch64) V2RAYA_ARCH="arm64" ;;
    armv7|armhf) V2RAYA_ARCH="armv7" ;;
    loongarch64) V2RAYA_ARCH="loongarch64" ;;
    mips64) V2RAYA_ARCH="mips64" ;;
    mips64le) V2RAYA_ARCH="mips64le" ;;
    mips32) V2RAYA_ARCH="mips32" ;;
    mips32le) V2RAYA_ARCH="mips32le" ;;
    riscv64) V2RAYA_ARCH="riscv64" ;;
    *) V2RAYA_ARCH="x64" ;;
esac

# Xray-core Linux 架构映射
case "$ARCH" in
    amd64|x86_64) XRAY_ARCH="64" ;;
    arm64|aarch64) XRAY_ARCH="arm64-v8a" ;;
    armv7|armhf) XRAY_ARCH="arm32-v7a" ;;
    *) XRAY_ARCH="64" ;;
esac
# =================================================

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

# 检测系统架构
detect_arch() {
    local machine=$(uname -m)
    case "$machine" in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l) ARCH="armv7" ;;
        *) ARCH="$machine" ;;
    esac
    print_info "检测到系统架构: $ARCH"
}

# 检查依赖工具
check_dependencies() {
    print_info "检查并安装依赖工具..."

    # 确保使用 sudo 权限
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用 sudo 运行此脚本"
        exit 1
    fi

    # 更新 apt 缓存
    print_info "更新 APT 缓存..."
    apt update -qq

    # 检查并安装 jq
    if ! command -v jq &> /dev/null; then
        print_info "安装 jq..."
        apt install -y jq
    fi

    # 检查并安装 unzip
    if ! command -v unzip &> /dev/null; then
        print_info "安装 unzip..."
        apt install -y unzip
    fi

    # 检查 curl 或 wget
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        print_info "安装 curl..."
        apt install -y curl
    fi

    print_info "依赖检查通过"
}

# 获取最新版本号和文件名
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

# 下载文件
download_file() {
    local url=$1
    local output=$2
    local name=$3

    print_info "正在下载 $name..."

    if ! wget -q --show-progress -O "$output" "$url"; then
        print_error "下载 $name 失败"
        print_error "URL: $url"
        exit 1
    fi

    if [ ! -f "$output" ]; then
        print_error "下载 $name 后文件不存在: $output"
        exit 1
    fi

    local size=$(du -h "$output" | cut -f1)
    print_info "$name 下载完成 (大小: $size)"
}

# 执行前置检查
detect_arch
check_dependencies

# 创建临时目录
TEMP_DIR=$(mktemp -d)
print_info "创建临时目录: $TEMP_DIR"

# 清理函数
cleanup() {
    print_info "清理临时文件..."
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# 进入临时目录
cd "$TEMP_DIR"

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

print_info ""
print_info "========================================"
print_info "版本信息"
print_info "========================================"
print_info "v2rayA:  ${V2RAYA_VERSION}"
print_info "Xray-core: ${XRAY_VERSION}"
print_info "========================================"
print_info ""

# 下载 v2rayA 包
download_file "$V2RAYA_URL" "$V2RAYA_DEB" "v2rayA"

# 下载 Xray 包
download_file "$XRAY_URL" "$XRAY_ZIP" "Xray-core"

# 解压 Xray 包
print_info "正在解压 Xray-core..."
if ! unzip -q "$XRAY_ZIP" -d "xray"; then
    print_error "解压 Xray-core 失败"
    exit 1
fi
print_info "Xray-core 解压完成"

# 从 Xray zip 中提取二进制文件
print_info "正在准备 Xray 二进制文件..."
if [ -f "xray/xray" ]; then
    chmod +x xray/xray
    print_info "Xray 二进制文件已准备就绪"
elif [ -f "xray/Xray" ]; then
    chmod +x xray/Xray
    print_info "Xray 二进制文件已准备就绪"
else
    print_error "未找到 Xray 二进制文件"
    ls -la xray/
    exit 1
fi

# 确认文件存在
if [ ! -f "$V2RAYA_DEB" ]; then
    print_error "找不到 v2rayA 安装包: $V2RAYA_DEB"
    exit 1
fi

print_info ""
print_info "========================================"
print_info "文件检查完成"
print_info "========================================"
print_info "v2rayA:    $V2RAYA_DEB"
print_info "Xray-core:  $XRAY_ZIP (已解压)"
print_info "========================================"
print_info ""

# 创建简化安装脚本（适配动态版本）
print_info "创建简化安装脚本..."
cat > install_v2raya_simple.sh <<'INSTALLEOF'
#!/bin/bash

# Ubuntu 22.04 v2rayA + Xray 简化安装脚本（动态版本）
# 功能：备份源配置、更新为阿里云镜像、安装 v2rayA 和 Xray

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
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

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    print_error "请使用 sudo 运行此脚本"
    exit 1
fi

# 步骤 1: 备份现有源配置并更新为阿里云镜像
print_info "步骤 1: 备份并更新 APT 源配置"

if [ -f /etc/apt/sources.list ]; then
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
    print_info "已备份原有源配置到 /etc/apt/sources.list.bak"
fi

print_info "更新为阿里云镜像源..."
tee /etc/apt/sources.list <<-'EOF'
deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy main restricted universe multiverse
deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy-backports main restricted universe multiverse
deb http://mirrors.cloud.aliyuncs.com/ubuntu/ jammy-security main restricted universe multiverse
EOF

print_info "更新 APT 缓存..."
apt update

print_info "APT 源配置完成"

# 步骤 2: 安装 v2rayA 和 Xray
print_info "步骤 2: 安装 v2rayA 和 Xray"

# 获取当前目录下的 .deb 文件（应该只有一个 v2rayA .deb）
V2RAYA_DEB=$(ls -1 *.deb 2>/dev/null | grep -E "^installer_debian_.*\.deb$" | head -n 1)

if [ -z "$V2RAYA_DEB" ]; then
    print_error "未找到 v2rayA 安装包 (installer_debian_*.deb)"
    ls -la
    exit 1
fi

print_info "安装 $V2RAYA_DEB..."
dpkg -i "$V2RAYA_DEB" || true

# 安装 Xray 二进制文件
if [ -d "xray" ]; then
    print_info "安装 Xray-core 二进制文件..."
    install -m 755 xray/xray /usr/local/bin/xray 2>/dev/null || \
        install -m 755 xray/Xray /usr/local/bin/xray 2>/dev/null || {
        print_error "无法安装 Xray 二进制文件"
        exit 1
    }
    print_info "Xray-core 安装完成"
else
    print_warning "未找到 Xray 二进制文件，跳过 Xray 安装"
fi

# 修复依赖关系
print_info "修复依赖关系..."
apt --fix-broken install -y

print_info "软件包安装完成"

# 步骤 3: 重载并重启服务
print_info "步骤 3: 重载并重启 v2rayA 服务"

print_info "重载 systemd 配置..."
systemctl daemon-reload

print_info "重启 v2rayA 服务..."
systemctl restart v2raya

print_info "设置 v2rayA 开机自启..."
systemctl enable v2raya

# 检查服务状态
print_info "检查 v2rayA 服务状态..."
if systemctl is-active --quiet v2raya; then
    print_info "v2rayA 服务运行正常"
else
    print_warning "v2rayA 服务未运行，请检查配置"
    systemctl status v2raya --no-pager
fi

print_info ""
print_info "========================================"
print_info "安装完成！"
print_info "v2rayA Web 界面: http://localhost:2017"
print_info "启动服务: sudo systemctl start v2raya"
print_info "停止服务: sudo systemctl stop v2raya"
print_info "查看状态: sudo systemctl status v2raya"
print_info "========================================"
INSTALLEOF

chmod +x install_v2raya_simple.sh

# 执行安装脚本
print_info "开始执行安装脚本..."
bash install_v2raya_simple.sh
