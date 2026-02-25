#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

FORCE=0
PURGE=0
INSTALL_METHOD="none"
OS_TYPE="unknown"
OS_ID="unknown"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

usage() {
    cat << 'EOF'
Usage: sudo ./uninstall.sh [--force] [--purge] [--help]

Options:
  --force     Continue even if some operations fail.
  --purge     Remove configuration, cache, and log files in addition to binaries.
  -h, --help  Show this help message.

The script stops & disables the v2raya service, removes v2rayA (dpkg/rpm/local),
deletes Xray binaries and geoip/geosite data, and optionally purges configs.
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force) FORCE=1 ;;
            --purge) PURGE=1 ;;
            -h|--help) usage; exit 0 ;;
            *)
                log_error "未知参数: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "请使用 root 权限运行 (sudo ./uninstall.sh ...)"
        exit 1
    fi
}

run_cmd() {
    local action="$1"
    shift
    set +e
    "$@" || {
        if [[ $FORCE -eq 1 ]]; then
            log_warn "$action 失败 (exit $?),由于 --force 已启用，继续执行"
        else
            log_error "$action 失败 (exit $?)"
            exit $?
        fi
    }
}

remove_path() {
    local target="$1"
    if [[ -L "$target" || -e "$target" ]]; then
        run_cmd "删除 $target" rm -rf -- "$target"
    fi
}

detect_os() {
    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
    fi
    
    case "$OS_ID" in
        ubuntu|debian) OS_TYPE="debian" ;;
        rhel|centos|rocky|almalinux|fedora) OS_TYPE="rpm" ;;
        *) OS_TYPE="unknown" ;;
    esac
    
    log_info "检测到操作系统: ${OS_ID} (类型: ${OS_TYPE})"
}

detect_install_method() {
    if dpkg -s v2raya >/dev/null 2>&1; then
        INSTALL_METHOD="dpkg"
    elif rpm -q v2raya >/dev/null 2>&1; then
        INSTALL_METHOD="rpm"
    elif [[ -x /usr/local/bin/v2raya || -x /usr/bin/v2raya ]]; then
        INSTALL_METHOD="binary"
    else
        INSTALL_METHOD="none"
    fi
    log_info "检测到安装方式: ${INSTALL_METHOD}"
}

stop_service() {
    if ! command -v systemctl >/dev/null 2>&1; then
        log_warn "systemctl 不可用，跳过服务操作"
        return
    fi
    
    if systemctl list-unit-files v2raya.service >/dev/null 2>&1; then
        run_cmd "停止 v2raya 服务" systemctl stop v2raya
        run_cmd "禁用 v2raya 服务" systemctl disable v2raya
    else
        log_info "未检测到 v2raya systemd 服务"
    fi
}

remove_v2raya_package() {
    case "$INSTALL_METHOD" in
        dpkg)
            local apt_action="remove"
            [[ $PURGE -eq 1 ]] && apt_action="purge"
            if command -v apt-get >/dev/null 2>&1; then
                run_cmd "APT ${apt_action} v2raya" env DEBIAN_FRONTEND=noninteractive apt-get -y "$apt_action" v2raya
            else
                local dpkg_action="r"
                [[ $PURGE -eq 1 ]] && dpkg_action="P"
                run_cmd "dpkg ${dpkg_action} v2raya" dpkg "$dpkg_action" v2raya
            fi
            ;;
        rpm)
            if command -v dnf >/dev/null 2>&1; then
                run_cmd "dnf remove v2raya" dnf -y remove v2raya
            elif command -v yum >/dev/null 2>&1; then
                run_cmd "yum remove v2raya" yum -y remove v2raya
            else
                run_cmd "rpm remove v2raya" rpm -e v2raya
            fi
            ;;
        binary)
            remove_path "/usr/local/bin/v2raya"
            remove_path "/usr/bin/v2raya"
            ;;
        none)
            log_info "未检测到 v2rayA 包或二进制，跳过软件卸载"
            ;;
    esac
}

remove_xray_binary() {
    local removed=0
    declare -a candidates=(
        "$(command -v xray 2>/dev/null)"
        "/usr/local/bin/xray"
        "/usr/local/bin/Xray"
        "/usr/bin/xray"
        "/usr/bin/Xray"
    )
    
    for path in "${candidates[@]}"; do
        [[ -z "$path" ]] && continue
        if [[ -e "$path" ]]; then
            remove_path "$path"
            removed=1
        fi
    done
    
    if [[ $removed -eq 0 ]]; then
        log_info "未找到 Xray 二进制"
    fi
}

remove_geo_files() {
    local removed=0
    local dirs=(
        "/usr/local/share/xray"
        "/usr/share/xray"
        "/usr/local/bin"
        "/usr/bin"
        "/var/lib/v2ray"
        "/var/lib/v2rayA"
        "/etc/v2ray"
        "/etc/v2rayA"
    )
    
    for dir in "${dirs[@]}"; do
        for file in geoip.dat geosite.dat; do
            if [[ -f "${dir}/${file}" ]]; then
                remove_path "${dir}/${file}"
                removed=1
            fi
        done
    done
    
    if [[ $removed -eq 0 ]]; then
        log_info "未检测到 geoip.dat / geosite.dat 文件"
    fi
}

cleanup_configs() {
    if [[ $PURGE -eq 0 ]]; then
        log_info "未指定 --purge，保留配置与日志目录"
        return
    fi
    
    log_info "执行 --purge，删除配置、缓存、日志目录"
    local paths=(
        "/etc/v2ray"
        "/etc/v2rayA"
        "/var/lib/v2ray"
        "/var/lib/v2rayA"
        "/var/log/v2ray"
        "/var/log/v2rayA"
        "/var/cache/v2ray"
        "/var/cache/v2rayA"
        "/etc/systemd/system/v2raya.service"
        "/usr/lib/systemd/system/v2raya.service"
    )
    
    for p in "${paths[@]}"; do
        remove_path "$p"
    done
}

reload_systemd() {
    if command -v systemctl >/dev/null 2>&1; then
        run_cmd "systemd daemon-reload" systemctl daemon-reload
    fi
}

main() {
    parse_args "$@"
    require_root
    detect_os
    detect_install_method
    stop_service
    remove_v2raya_package
    remove_xray_binary
    remove_geo_files
    cleanup_configs
    reload_systemd
    log_info "卸载流程完成。如需彻底清理用户级配置，请手动删除 ~/.config/v2rayA 等目录。"
}

main "$@"
