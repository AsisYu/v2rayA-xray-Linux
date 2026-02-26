#!/bin/bash

# v2rayA + Xray 一键安装引导脚本
# 支持 Debian/Ubuntu 和 CentOS/RHEL 系列
# 用户通过 curl 执行此脚本，会自动从 GitHub 获取最新版本并安装

set -e

# ==================== 配置区域 ====================
# GitHub 仓库信息
V2RAYA_REPO="v2rayA/v2rayA"
XRAY_REPO="XTLS/Xray-core"

# =================================================

# GitHub API 代理配置（国内服务器可设置）
# 使用方式：export GITHUB_API_PROXY=https://v6.gh-proxy.org/https://api.github.com
GITHUB_API_PROXY="${GITHUB_API_PROXY:-}"

# GitHub 文件下载代理（国内服务器可设置）
# 使用方式：export GITHUB_DOWNLOAD_PROXY=https://v6.gh-proxy.org
GITHUB_DOWNLOAD_PROXY="${GITHUB_DOWNLOAD_PROXY:-}"

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

# 检测操作系统类型
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
    fi

    if [ -z "$ID" ]; then
        print_error "无法检测操作系统类型"
        exit 1
    fi

    OS_TYPE=""
    PKG_MGR=""

    case "$ID" in
        ubuntu|debian)
            OS_TYPE="debian"
            PKG_MGR="apt"
            ;;
        rhel|centos|rocky|almalinux)
            OS_TYPE="rpm"
            # CentOS 8/RHEL 8+ 使用 dnf
            # 提取主版本号（处理 8.10 这样的版本号）
            VERSION_MAJOR=$(echo "$VERSION_ID" | cut -d. -f1)
            if [ "$VERSION_MAJOR" -ge "8" ] || [ "$ID" = "fedora" ] || [ "$ID" = "rocky" ] || [ "$ID" = "almalinux" ]; then
                PKG_MGR="dnf"
            else
                PKG_MGR="yum"
            fi
            ;;
        fedora)
            OS_TYPE="rpm"
            PKG_MGR="dnf"
            ;;
        *)
            print_error "不支持的操作系统: $ID"
            print_error "支持的系统: Debian/Ubuntu, CentOS/RHEL, Rocky Linux, AlmaLinux, Fedora"
            exit 1
            ;;
    esac

    print_info "检测到操作系统: $OS_TYPE ($ID $VERSION_ID)"
}

# 检查依赖工具
check_dependencies() {
    print_info "检查并安装依赖工具..."

    # 确保使用 sudo 权限
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用 sudo 运行此脚本"
        exit 1
    fi

    if [ "$OS_TYPE" = "debian" ]; then
        # Debian/Ubuntu 系统 - 使用 apt
        print_info "更新 APT 缓存..."
        if ! apt update -qq; then
            print_error "APT 更新失败，请检查网络连接或配置正确的软件源"
            exit 1
        fi

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
    else
        # CentOS/RHEL 系统 - 使用 yum/dnf
        if ! command -v curl &> /dev/null; then
            print_info "安装 curl..."
            $PKG_MGR install -y curl
        fi

        if ! command -v jq &> /dev/null; then
            print_info "安装 jq..."
            $PKG_MGR install -y jq
        fi

        if ! command -v unzip &> /dev/null; then
            print_info "安装 unzip..."
            $PKG_MGR install -y unzip
        fi
    fi

    print_info "依赖检查通过"
}

# 获取最新版本号和文件名
get_latest_version() {
    local repo=$1
    local name=$2
    local version
    local filename
    local release_json
    local api_url
    local max_retries=3
    local retry=0

    print_info "正在获取 $name 最新版本..."

    # 构造 API URL（支持代理）
    if [ -n "$GITHUB_API_PROXY" ]; then
        api_url="${GITHUB_API_PROXY}/repos/${repo}/releases/latest"
        print_info "使用 GitHub API 代理: $GITHUB_API_PROXY"
    else
        api_url="https://api.github.com/repos/${repo}/releases/latest"
        print_warning "未检测到 GITHUB_API_PROXY 环境变量，直接连接 GitHub API"
        print_warning "如需使用代理，请执行:"
        print_warning "  sudo -E bash -c 'GITHUB_API_PROXY=... GITHUB_DOWNLOAD_PROXY=... curl ... | bash'"
    fi

    # 带重试的 API 调用
    while [ $retry -lt $max_retries ]; do
        release_json=$(curl -s --max-time 30 "$api_url" 2>/dev/null) || true

        if [ -n "$release_json" ] && [ "$(echo "$release_json" | jq -r '.tag_name' 2>/dev/null)" != "null" ]; then
            break
        fi

        retry=$((retry + 1))
        if [ $retry -lt $max_retries ]; then
            print_warning "获取 $name 版本失败，正在重试 ($retry/$max_retries)..."
            sleep 2
        fi
    done

    if [ -z "$release_json" ]; then
        print_error "无法获取 $name 的 release 信息"
        print_error "请检查网络连接或设置 GitHub API 代理："
        print_error "  export GITHUB_API_PROXY=https://v6.gh-proxy.org/https://api.github.com"
        exit 1
    fi

    version=$(echo "$release_json" | jq -r '.tag_name')

    if [ -z "$version" ] || [ "$version" = "null" ]; then
        print_error "无法获取 $name 的最新版本号"
        print_error "请检查网络连接或稍后重试"
        exit 1
    fi

    print_info "$name 最新版本: $version"

    # 去掉版本号的 v 前缀（用于文件名匹配）
    local version_num="${version#v}"

    # 获取对应架构的文件名
    if [ "$OS_TYPE" = "debian" ]; then
        # Debian/Ubuntu - 使用 .deb 包
        if [ "$name" = "v2rayA" ]; then
            # 排除 sha256.txt 校验文件，只下载实际的 .deb 包
            filename=$(echo "$release_json" | jq -r ".assets[] | select(.name | endswith(\".deb\") and (contains(\"${V2RAYA_ARCH}\")) and (contains(\"sha256\") | not)) | .name")
            if [ -z "$filename" ]; then
                print_error "无法找到 $name 的 ${V2RAYA_ARCH} .deb 文件"
                exit 1
            fi
            # 检查是否匹配多个文件（多个匹配会被 jq 用空格分隔）
            if [[ "$filename" == *" "* ]]; then
                print_error "找到多个匹配的 .deb 文件: $filename"
                print_error "请手动选择正确的文件"
                exit 1
            fi
        else
            filename=$(echo "$release_json" | jq -r ".assets[] | select(.name == \"Xray-linux-${XRAY_ARCH}.zip\") | .name")
            if [ -z "$filename" ]; then
                print_error "无法找到 $name 的 ${XRAY_ARCH} .zip 文件"
                exit 1
            fi
        fi
    else
        # CentOS/RHEL - 优先使用 RPM 包，回退到通用二进制
        if [ "$name" = "v2rayA" ]; then
            # 优先使用 RPM 包（使用 contains 匹配，因为版本号格式可能不同）
            filename=$(echo "$release_json" | jq -r ".assets[] | select(.name | endswith(\".rpm\") and contains(\"installer_redhat_${V2RAYA_RPM_ARCH}\") and (contains(\"sha256\") | not)) | .name")
            # 如果 RPM 不存在，回退到通用二进制
            if [ -z "$filename" ]; then
                print_warning "未找到 $name 的 RPM 包，将使用通用二进制"
                # 通用二进制使用 x64 而不是 amd64
                local binary_arch="${V2RAYA_RPM_ARCH}"
                filename=$(echo "$release_json" | jq -r ".assets[] | select(.name == \"v2raya_linux_${binary_arch}_${version_num}\") | .name")
                if [ -z "$filename" ]; then
                    print_error "无法找到 $name 的 ${binary_arch} 二进制文件"
                    exit 1
                fi
            fi
        else
            filename=$(echo "$release_json" | jq -r ".assets[] | select(.name == \"Xray-linux-${XRAY_ARCH}.zip\") | .name")
            if [ -z "$filename" ]; then
                print_error "无法找到 $name 的 ${XRAY_ARCH} .zip 文件"
                exit 1
            fi
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

    # 优先使用 wget，如果不存在则使用 curl
    if command -v wget &> /dev/null; then
        if ! wget --progress=bar:force -O "$output" "$url"; then
            print_error "下载 $name 失败"
            print_error "URL: $url"
            exit 1
        fi
    elif command -v curl &> /dev/null; then
        if ! curl -L --fail --show-error -o "$output" "$url"; then
            print_error "下载 $name 失败"
            print_error "URL: $url"
            exit 1
        fi
    else
        print_error "找不到 wget 或 curl 下载工具"
        exit 1
    fi

    if [ ! -f "$output" ]; then
        print_error "下载 $name 后文件不存在: $output"
        exit 1
    fi

    local size=$(du -h "$output" | cut -f1)
    print_info "$name 下载完成 (大小: $size)"
}

# 生成安装脚本
generate_install_script() {
    local v2raya_file=$1
    local v2raya_version=$2
    local xray_version=$3

    print_info "生成安装脚本..."

    if [ "$OS_TYPE" = "debian" ]; then
        # Debian/Ubuntu 安装脚本
        cat > install_v2raya_simple.sh << DEBEOF
#!/bin/bash

# v2rayA + Xray 简化安装脚本（动态版本）
# 功能：安装 v2rayA 和 Xray

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "\${GREEN}[INFO]\${NC} \$1"
}

print_error() {
    echo -e "\${RED}[ERROR]\${NC} \$1"
}

print_warning() {
    echo -e "\${YELLOW}[WARNING]\${NC} \$1"
}

# 检查是否为 root 用户
if [ "\$EUID" -ne 0 ]; then
    print_error "请使用 sudo 运行此脚本"
    exit 1
fi

# 步骤 1: 更新 APT 缓存
print_info "步骤 1: 更新 APT 缓存"

print_info "更新 APT 缓存..."
if ! apt update; then
    print_error "APT 更新失败，请检查网络连接或配置正确的软件源"
    exit 1
fi

print_info "APT 缓存更新成功"

# 步骤 2: 安装 v2rayA 和 Xray
print_info "步骤 2: 安装 v2rayA 和 Xray"

# 获取当前目录下的 .deb 文件（应该只有一个 v2rayA .deb）
V2RAYA_DEB=\$(ls -1 *.deb 2>/dev/null | grep -E "installer_debian" | head -n 1)
if [ -z "\$V2RAYA_DEB" ]; then
    print_error "未找到 v2rayA 安装包 (installer_debian_*.deb)"
    ls -la
    exit 1
fi

print_info "安装 \$V2RAYA_DEB..."
dpkg -i "\$V2RAYA_DEB" || true

# 检测 Xray 二进制路径（优先使用已安装的）
XRAY_BIN=""
if command -v xray &> /dev/null; then
    XRAY_BIN=$(command -v xray)
    print_info "检测到已安装的 Xray: \$XRAY_BIN"
elif [ -f "/usr/bin/xray" ]; then
    XRAY_BIN="/usr/bin/xray"
elif [ -f "/usr/local/bin/xray" ]; then
    XRAY_BIN="/usr/local/bin/xray"
fi

if [ -d "xray" ]; then
    # 有新下载的 Xray，安装到检测到的目录
    if [ -n "\$XRAY_BIN" ]; then
        TARGET_DIR=\$(dirname "\$XRAY_BIN")
    else
        # 默认安装到 /usr/local/bin
        TARGET_DIR="/usr/local/bin"
    fi
    print_info "安装 Xray-core 二进制文件到 \$TARGET_DIR..."
    install -m 755 xray/xray "\$TARGET_DIR/xray" 2>/dev/null || \\
        install -m 755 xray/Xray "\$TARGET_DIR/xray" 2>/dev/null || {
        print_error "无法安装 Xray 二进制文件"
        exit 1
    }
    XRAY_BIN="\$TARGET_DIR/xray"
    print_info "Xray-core 安装完成: \$XRAY_BIN"
elif [ -n "\$XRAY_BIN" ]; then
    print_info "使用系统已有的 Xray: \$XRAY_BIN"
else
    print_warning "未找到 Xray 二进制文件，跳过 Xray 安装"
fi

# 步骤 3: 下载 geoip.dat 和 geosite.dat
print_info "步骤 3: 下载 geoip.dat 和 geosite.dat"

# 数据文件放在 Xray 所在目录
if [ -n "\$XRAY_BIN" ]; then
    V2RAYA_DIR=\$(dirname "\$XRAY_BIN")
    mkdir -p "\$V2RAYA_DIR"
    print_info "数据文件目录: \$V2RAYA_DIR"
else
    # XRAY_BIN 为空时，使用默认目录
    V2RAYA_DIR="/usr/local/bin"
    mkdir -p "\$V2RAYA_DIR"
    print_info "数据文件目录: \$V2RAYA_DIR（默认）"
fi

# 检查是否设置了 GitHub 下载代理
if [ -n "\$GITHUB_DOWNLOAD_PROXY" ]; then
    DOWNLOAD_PROXY="\${GITHUB_DOWNLOAD_PROXY}"
    print_info "使用 GitHub 下载代理"
else
    DOWNLOAD_PROXY=""
    print_warning "未设置 GitHub 下载代理，直接下载"
fi

# 下载 geoip.dat
GEOIP_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
if [ -n "\$DOWNLOAD_PROXY" ]; then
    GEOIP_URL="\${DOWNLOAD_PROXY}/\${GEOIP_URL}"
fi

print_info "下载 geoip.dat..."
if command -v curl &> /dev/null; then
    curl -fsSL --max-time 300 "\$GEOIP_URL" -o "\$V2RAYA_DIR/geoip.dat"
elif command -v wget &> /dev/null; then
    wget --timeout=300 -O "\$V2RAYA_DIR/geoip.dat" "\$GEOIP_URL"
else
    print_warning "无法下载 geoip.dat，将使用默认规则"
fi

# 下载 geosite.dat
GEOSITE_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
if [ -n "\$DOWNLOAD_PROXY" ]; then
    GEOSITE_URL="\${DOWNLOAD_PROXY}/\${GEOSITE_URL}"
fi

print_info "下载 geosite.dat..."
if command -v curl &> /dev/null; then
    curl -fsSL --max-time 300 "\$GEOSITE_URL" -o "\$V2RAYA_DIR/geosite.dat"
elif command -v wget &> /dev/null; then
    wget --timeout=300 -O "\$V2RAYA_DIR/geosite.dat" "\$GEOSITE_URL"
else
    print_warning "无法下载 geosite.dat，将使用默认规则"
fi

# 设置文件权限
if [ -f "\$V2RAYA_DIR/geoip.dat" ]; then
    chmod 644 "\$V2RAYA_DIR/geoip.dat"
    print_info "geoip.dat 下载完成"
fi
if [ -f "\$V2RAYA_DIR/geosite.dat" ]; then
    chmod 644 "\$V2RAYA_DIR/geosite.dat"
    print_info "geosite.dat 下载完成"
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
systemctl restart v2raya || print_warning "v2raya 服务重启可能失败"

print_info "设置 v2rayA 开机自启..."
systemctl enable v2raya

# 检查服务状态
print_info "检查 v2rayA 服务状态..."
if systemctl is-active --quiet v2raya; then
    print_info "v2rayA 服务运行正常"
else
    print_warning "v2rayA 服务未运行，请检查配置"
    systemctl status v2raya --no-pager || true
fi

print_info ""
print_info "========================================"
print_info "安装完成！"
print_info "v2rayA Web 界面: http://localhost:2017"
print_info "启动服务: sudo systemctl start v2raya"
print_info "停止服务: sudo systemctl stop v2raya"
print_info "查看状态: sudo systemctl status v2raya"
print_info "========================================"
DEBEOF

        chmod +x install_v2raya_simple.sh
    else
        # RPM 系统安装脚本
        cat > install_v2raya_simple.sh << RPMEOF
#!/bin/bash

# v2rayA + Xray RPM 系统安装脚本（动态版本）
# 功能：安装 v2rayA 和 Xray

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "\${GREEN}[INFO]\${NC} \$1"
}

print_error() {
    echo -e "\${RED}[ERROR]\${NC} \$1"
}

print_warning() {
    echo -e "\${YELLOW}[WARNING]\${NC} \$1"
}

# 检查是否为 root 用户
if [ "\$EUID" -ne 0 ]; then
    print_error "请使用 sudo 运行此脚本"
    exit 1
fi

# 检测包管理器
if command -v dnf &> /dev/null; then
    PKG_MGR="dnf"
else
    PKG_MGR="yum"
fi

# 步骤 1: 安装 v2rayA
print_info "步骤 1: 安装 v2rayA"

V2RAYA_FILE="$v2raya_file"
if [[ "\$V2RAYA_FILE" == *.rpm ]]; then
    # 使用 RPM 包
    print_info "使用 RPM 包安装 v2rayA..."
    if ! \$PKG_MGR install -y "\$V2RAYA_FILE"; then
        print_error "RPM 安装失败"
        exit 1
    fi
    print_info "v2rayA 安装完成"
else
    # 使用通用二进制
    print_info "将 v2raya 二进制复制到 /usr/local/bin/..."
    install -m 755 "\$V2RAYA_FILE" /usr/local/bin/v2raya
    print_info "v2rayA 安装完成"
fi

# 步骤 2: 安装 Xray
print_info "步骤 2: 安装 Xray"

XRAY_BIN=""
if command -v xray &> /dev/null; then
    XRAY_BIN=$(command -v xray)
    print_info "检测到已安装的 Xray: \$XRAY_BIN"
elif [ -f "/usr/bin/xray" ]; then
    XRAY_BIN="/usr/bin/xray"
elif [ -f "/usr/local/bin/xray" ]; then
    XRAY_BIN="/usr/local/bin/xray"
fi

if [ -d "xray" ]; then
    if [ -n "\$XRAY_BIN" ]; then
        TARGET_DIR=\$(dirname "\$XRAY_BIN")
    else
        TARGET_DIR="/usr/local/bin"
    fi
    print_info "安装 Xray-core 二进制文件到 \$TARGET_DIR..."
    install -m 755 xray/xray "\$TARGET_DIR/xray" 2>/dev/null || \
        install -m 755 xray/Xray "\$TARGET_DIR/xray" 2>/dev/null || {
        print_error "无法安装 Xray 二进制文件"
        exit 1
    }
    XRAY_BIN="\$TARGET_DIR/xray"
    print_info "Xray-core 安装完成: \$XRAY_BIN"
elif [ -n "\$XRAY_BIN" ]; then
    print_info "使用系统已有的 Xray: \$XRAY_BIN"
else
    print_warning "未找到 Xray 二进制文件，跳过 Xray 安装"
fi

# 步骤 3: 下载 geoip.dat 和 geosite.dat
print_info "步骤 3: 下载 geoip.dat 和 geosite.dat"

# 数据文件放在 Xray 所在目录
if [ -n "\$XRAY_BIN" ]; then
    V2RAYA_DIR=\$(dirname "\$XRAY_BIN")
    mkdir -p "\$V2RAYA_DIR"
    print_info "数据文件目录: \$V2RAYA_DIR"
else
    # XRAY_BIN 为空时，使用默认目录
    V2RAYA_DIR="/usr/local/bin"
    mkdir -p "\$V2RAYA_DIR"
    print_info "数据文件目录: \$V2RAYA_DIR（默认）"
fi

# 检查是否设置了 GitHub 下载代理
if [ -n "\$GITHUB_DOWNLOAD_PROXY" ]; then
    DOWNLOAD_PROXY="\${GITHUB_DOWNLOAD_PROXY}"
    print_info "使用 GitHub 下载代理"
else
    DOWNLOAD_PROXY=""
    print_warning "未设置 GitHub 下载代理，直接下载"
fi

# 下载 geoip.dat
GEOIP_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
if [ -n "\$DOWNLOAD_PROXY" ]; then
    GEOIP_URL="\${DOWNLOAD_PROXY}/\${GEOIP_URL}"
fi

print_info "下载 geoip.dat..."
if command -v curl &> /dev/null; then
    curl -fsSL --max-time 300 "\$GEOIP_URL" -o "\$V2RAYA_DIR/geoip.dat"
elif command -v wget &> /dev/null; then
    wget --timeout=300 -O "\$V2RAYA_DIR/geoip.dat" "\$GEOIP_URL"
else
    print_warning "无法下载 geoip.dat，将使用默认规则"
fi

# 下载 geosite.dat
GEOSITE_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
if [ -n "\$DOWNLOAD_PROXY" ]; then
    GEOSITE_URL="\${DOWNLOAD_PROXY}/\${GEOSITE_URL}"
fi

print_info "下载 geosite.dat..."
if command -v curl &> /dev/null; then
    curl -fsSL --max-time 300 "\$GEOSITE_URL" -o "\$V2RAYA_DIR/geosite.dat"
elif command -v wget &> /dev/null; then
    wget --timeout=300 -O "\$V2RAYA_DIR/geosite.dat" "\$GEOSITE_URL"
else
    print_warning "无法下载 geosite.dat，将使用默认规则"
fi

# 设置文件权限
if [ -f "\$V2RAYA_DIR/geoip.dat" ]; then
    chmod 644 "\$V2RAYA_DIR/geoip.dat"
    print_info "geoip.dat 下载完成"
fi
if [ -f "\$V2RAYA_DIR/geosite.dat" ]; then
    chmod 644 "\$V2RAYA_DIR/geosite.dat"
    print_info "geosite.dat 下载完成"
fi

# 步骤 4: 配置 systemd 服务
print_info "步骤 3: 配置 v2rayA 服务"

if [[ "\$V2RAYA_FILE" == *.rpm ]]; then
    # RPM 包自带 systemd 服务，只需启用
    print_info "RPM 包已包含 systemd 服务，启用服务..."
else
    # 通用二进制需要手动创建 systemd 服务
    print_info "创建 systemd 服务文件..."
    cat > /etc/systemd/system/v2raya.service << 'SERVICEEOF'
[Unit]
Description=v2rayA Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/v2raya
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
SERVICEEOF
fi

systemctl daemon-reload
systemctl enable v2raya

print_info "systemd 服务配置完成"

# 步骤 5: 启动服务
print_info "步骤 5: 启动 v2rayA 服务"

systemctl start v2raya || print_warning "v2raya 服务启动可能失败"

# 检查服务状态
sleep 2
print_info "检查 v2rayA 服务状态..."
if systemctl is-active --quiet v2raya; then
    print_info "v2rayA 服务运行正常"
else
    print_warning "v2rayA 服务未运行，请检查配置"
    systemctl status v2raya --no-pager || true
fi

print_info ""
print_info "========================================"
print_info "安装完成！"
print_info "v2rayA Web 界面: http://localhost:2017"
print_info "启动服务: systemctl start v2raya"
print_info "停止服务: systemctl stop v2raya"
print_info "查看状态: systemctl status v2raya"
print_info "========================================"
RPMEOF

        chmod +x install_v2raya_simple.sh
    fi
}

# 执行前置检查
detect_arch

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

# v2rayA RPM 架构映射（用于 CentOS/RHEL）
case "$ARCH" in
    amd64|x86_64) V2RAYA_RPM_ARCH="x64" ;;
    arm64|aarch64) V2RAYA_RPM_ARCH="arm64" ;;
    *) V2RAYA_RPM_ARCH="x64" ;;
esac

# Xray-core Linux 架构映射
case "$ARCH" in
    amd64|x86_64) XRAY_ARCH="64" ;;
    arm64|aarch64) XRAY_ARCH="arm64-v8a" ;;
    armv7|armhf) XRAY_ARCH="arm32-v7a" ;;
    *) XRAY_ARCH="64" ;;
esac

detect_os
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
V2RAYA_FILE=$(echo "$V2RAYA_INFO" | tail -1)

XRAY_INFO=$(get_latest_version "$XRAY_REPO" "Xray-core")
XRAY_VERSION=$(echo "$XRAY_INFO" | head -1)
XRAY_ZIP=$(echo "$XRAY_INFO" | tail -1)

# 构造下载 URL（支持代理）
if [ -n "$GITHUB_DOWNLOAD_PROXY" ]; then
    V2RAYA_URL="${GITHUB_DOWNLOAD_PROXY}/https://github.com/${V2RAYA_REPO}/releases/download/${V2RAYA_VERSION}/${V2RAYA_FILE}"
    XRAY_URL="${GITHUB_DOWNLOAD_PROXY}/https://github.com/${XRAY_REPO}/releases/download/${XRAY_VERSION}/${XRAY_ZIP}"
    print_info "使用 GitHub 下载代理: $GITHUB_DOWNLOAD_PROXY"
else
    V2RAYA_URL="https://github.com/${V2RAYA_REPO}/releases/download/${V2RAYA_VERSION}/${V2RAYA_FILE}"
    XRAY_URL="https://github.com/${XRAY_REPO}/releases/download/${XRAY_VERSION}/${XRAY_ZIP}"
fi

print_info ""
print_info "========================================"
print_info "版本信息"
print_info "========================================"
print_info "操作系统: $OS_TYPE ($ID $VERSION_ID)"
print_info "架构:      $ARCH"
print_info "v2rayA:     ${V2RAYA_VERSION}"
print_info "Xray-core:  ${XRAY_VERSION}"
print_info "========================================"
print_info ""

# 下载 v2rayA 包
download_file "$V2RAYA_URL" "$V2RAYA_FILE" "v2rayA"

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

# 生成并执行安装脚本
generate_install_script "$V2RAYA_FILE" "$V2RAYA_VERSION" "$XRAY_VERSION"

# 执行安装脚本
print_info "开始执行安装脚本..."
# 导出环境变量给安装脚本
export GITHUB_API_PROXY GITHUB_DOWNLOAD_PROXY
bash install_v2raya_simple.sh
