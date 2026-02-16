# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a v2rayA + Xray installer package for Ubuntu 22.04 (Jammy Jellyfish). The project provides a two-stage installation process:

1. **`setup.sh`** - Downloads the installer package from a remote URL and extracts it
2. **`install_v2raya_simple.sh`** - Performs the actual system installation

## Installation

### Quick Install
```bash
sudo bash setup.sh
```

### Manual Install (after downloading package)
```bash
cd v2raya-xray-installer-2.2.7.4
sudo bash install_v2raya_simple.sh
```

## Service Management

```bash
sudo systemctl start v2raya      # Start service
sudo systemctl stop v2raya       # Stop service
sudo systemctl restart v2raya   # Restart service
sudo systemctl status v2raya     # Check status
```

## Access

After installation, access the v2rayA web interface at: `http://localhost:2017`

## Architecture

### Two-Stage Installation

**Stage 1: `setup.sh`**
- Downloads the installer package from `DOWNLOAD_URL` (configurable)
- Extracts the package to a temporary directory
- Invokes `install_v2raya_simple.sh`

**Stage 2: `install_v2raya_simple.sh`**
- Backs up existing APT sources configuration
- Updates APT sources to Aliyun mirrors for faster downloads
- Installs `installer_debian_x64_2.2.7.4.deb` (v2rayA)
- Installs `xray_25.8.3_amd64.deb` (Xray core)
- Fixes any broken dependencies
- Reloads systemd and enables v2raya service

### Package Contents

The installer package (`v2raya-xray-installer-2.2.7.4.tar.gz`) contains:
- `installer_debian_x64_2.2.7.4.deb` - v2rayA web GUI for Project V
- `xray_25.8.3_amd64.deb` - Xray core
- `install_v2raya_simple.sh` - Installation script
- `README.txt` - Basic documentation

## Configuration

To update the download URL, modify `DOWNLOAD_URL` in `setup.sh`:

```bash
DOWNLOAD_URL="https://your-server/v2raya-xray-installer-2.2.7.4.tar.gz"
```

## System Requirements

- Ubuntu 22.04 (Jammy Jellyfish)
- Root/sudo privileges
