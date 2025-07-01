#!/bin/bash

#================================================================
#
#   System Required: CentOS 7+ / Debian 8+ / Ubuntu 16+
#   Description: TUIC-SERVER Installation Script
#
#================================================================

# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Get Arch
get_arch() {
    case $(uname -m) in
        x86_64|amd64)
            echo "x86_64-linux"
            ;;
        aarch64|arm64)
            echo "aarch64-linux"
            ;;
        *)
            echo "unsupported"
            ;;
    esac
}

# 1. Install TUIC
install_tuic() {
    echo -e "${green}开始安装 TUIC...${plain}"

    # 1.1 Completely remove past installations (except for TLS certificates)
    echo -e "${yellow}正在移除旧的安装...${plain}"
    systemctl stop tuic
    systemctl disable tuic
    rm -f /etc/systemd/system/tuic.service
    systemctl daemon-reload
    rm -rf /etc/tuic

    # 1.2 Create directory /etc/tuic
    echo -e "${yellow}正在创建目录 /etc/tuic...${plain}"
    mkdir -p /etc/tuic

    # 1.3 Download the latest server binary
    echo -e "${yellow}正在下载最新版的 TUIC 服务端...${plain}"
    arch=$(get_arch)
    if [ "$arch" == "unsupported" ]; then
        echo -e "${red}不支持的 CPU 架构！${plain}"
        exit 1
    fi

    # Get the latest version number from GitHub API
    latest_version=$(curl -s "https://api.github.com/repos/Itsusinn/tuic/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$latest_version" ]; then
        echo -e "${red}获取最新版本失败，请检查网络！${plain}"
        exit 1
    fi

    download_url="https://github.com/Itsusinn/tuic/releases/download/${latest_version}/tuic-server-${arch}"

    wget -O /etc/tuic/tuic "$download_url"
    if [ $? -ne 0 ]; then
        echo -e "${red}下载失败，请检查网络！${plain}"
        exit 1
    fi
    chmod +x /etc/tuic/tuic

    # 1.4 Edit configuration file
    echo -e "${yellow}正在配置 TUIC...${plain}"
    config_file="/etc/tuic/config.toml"

    # Ask for service port
    read -p "请输入服务端口号 [默认: 443]: " port
    [ -z "${port}" ] && port=443

    # Ask if zero_rtt_handshake should be enabled
    read -p "是否开启 zero_rtt_handshake (y/n) [默认: n]: " zero_rtt_handshake
    [ -z "${zero_rtt_handshake}" ] && zero_rtt_handshake="false"
    if [ "$zero_rtt_handshake" == "y" ]; then
        zero_rtt_handshake="true"
    else
        zero_rtt_handshake="false"
    fi

    # Set UUID and password
    read -p "请输入 UUID [留空则自动生成]: " uuid
    [ -z "${uuid}" ] && uuid=$(cat /proc/sys/kernel/random/uuid)
    read -p "请输入 password [留空则自动生成]: " password
    [ -z "${password}" ] && password=$(tr -dc 'a-z' < /dev/urandom | head -c 8)

    # Ask for certificate path
    echo "请选择证书路径获取方式:"
    echo "1) 自动适配 V2ray-agent 证书路径"
    echo "2) 自定义证书路径"
    echo "3) 使用默认配置路径"
    read -p "请输入选项 [1-3]: " cert_choice

    case $cert_choice in
        1)
            cert_path="/etc/v2ray-agent/tls/*.crt"
            key_path="/etc/v2ray-agent/tls/*.key"
            ;;
        2)
            read -p "请输入 fullchain 证书路径: " cert_path
            read -p "请输入私钥证书路径: " key_path
            ;;
        *)
            cert_path="/root/cert/cert.crt"
            key_path="/root/cert/private.key"
            echo -e "${yellow}请确保证书已上传至默认路径${plain}"
            ;;
    esac

    # Set send_window and receive_window
    read -p "请输入 send_window 窗口大小 [默认: 16777216]: " send_window
    [ -z "${send_window}" ] && send_window=16777216
    read -p "请输入 receive_window 窗口大小 [默认: 16777216]: " receive_window
    [ -z "${receive_window}" ] && receive_window=16777216

    # Write to config file
    cat > "$config_file" <<EOF
log_level = "info"
server = "[::]:${port}"
udp_relay_ipv6 = true
zero_rtt_handshake = ${zero_rtt_handshake}
dual_stack = true
auth_timeout = "3s"
task_negotiation_timeout = "3s"
gc_interval = "3s"
gc_lifetime = "15s"
max_external_packet_size = 1500
stream_timeout = "10s"


[users]
${uuid} = "${password}"


[tls]
self_sign = false
certificate = "${cert_path}"
private_key = "${key_path}"
alpn = ["h3"]


[quic]
initial_mtu = 1200
min_mtu = 1200
gso = true
pmtu = true
send_window = ${send_window}
receive_window = ${receive_window}
max_idle_time = "10s"


[quic.congestion_control]
controller = "bbr"
initial_window = 1048576
EOF

    # 1.5 Generate systemd service file
    echo -e "${yellow}正在生成 systemd 服务文件...${plain}"
    cat > /etc/systemd/system/tuic.service <<EOF
[Unit]
Description=TUIC Server
After=network.target

[Service]
ExecStart=/etc/tuic/tuic -c /etc/tuic/config.toml
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

    # 1.6 Enable and start the service
    echo -e "${yellow}正在启动 TUIC 服务...${plain}"
    systemctl daemon-reload
    systemctl enable tuic
    systemctl start tuic

    # 1.7 Check service status
    systemctl status tuic --no-pager -l

    # 1.8 Print configuration
    echo -e "${green}TUIC 安装完成!${plain}"
    echo -e "端口号: ${yellow}${port}${plain}"
    echo -e "UUID: ${yellow}${uuid}${plain}"
    echo -e "Password: ${yellow}${password}${plain}"
}

# 2. Restart TUIC
restart_tuic() {
    echo -e "${green}正在重启 TUIC 服务...${plain}"
    systemctl restart tuic
    echo -e "${green}TUIC 服务已重启!${plain}"
    systemctl status tuic --no-pager -l
}

# 3. Uninstall TUIC
uninstall_tuic() {
    echo -e "${red}确定要卸载 TUIC 吗? (y/n)${plain}"
    read -p "" choice
    if [ "$choice" == "y" ]; then
        echo -e "${yellow}正在卸载 TUIC...${plain}"
        systemctl stop tuic
        systemctl disable tuic
        rm -f /etc/systemd/system/tuic.service
        systemctl daemon-reload
        rm -rf /etc/tuic
        echo -e "${green}TUIC 卸载完成!${plain}"
    else
        echo -e "${plain}卸载已取消。${plain}"
    fi
}

# Main menu
main_menu() {
    clear
    echo "========================================"
    echo -e "          ${green}TUIC-SERVER 管理脚本${plain}"
    echo "========================================"
    echo "1. 安装 TUIC"
    echo "2. 重启 TUIC"
    echo "3. 卸载 TUIC"
    echo "0. 退出脚本"
    echo ""
    read -p "请输入选项 [0-3]: " num

    case "$num" in
        1)
            install_tuic
            ;;
        2)
            restart_tuic
            ;;
        3)
            uninstall_tuic
            ;;
        0)
            exit 0
            ;;
        *)
            clear
            echo -e "${red}请输入正确的数字 [0-3]${plain}"
            sleep 2
            main_menu
            ;;
    esac
}

main_menu