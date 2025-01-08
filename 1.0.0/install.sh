#!/bin/bash

set -e

INSTALL_DIR="/etc/tuic"
SERVICE_FILE="/etc/systemd/system/tuic.service"
CONFIG_FILE="$INSTALL_DIR/config_server.json"
BINARY_FILE="$INSTALL_DIR/tuic"
CERT_DIR="/root/cert"
DEFAULT_CERT="$CERT_DIR/cert.crt"
DEFAULT_KEY="$CERT_DIR/private.key"

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 打印信息
function print_info() {
    echo -e "${BLUE}$1${NC}"
}

function print_success() {
    echo -e "${GREEN}$1${NC}"
}

function print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

function print_error() {
    echo -e "${RED}$1${NC}"
}

# 检查并安装依赖
function install_dependencies() {
    print_info "检查并安装必要依赖..."
    if ! command -v uuidgen &>/dev/null; then
        print_info "未检测到 uuidgen，正在安装 uuid-runtime..."
        apt-get update -y && apt-get install uuid-runtime -y
        print_success "uuid-runtime 安装完成。"
    else
        print_success "uuidgen 可用，无需安装。"
    fi
}

# 检查 CPU 支持的指令集
function detect_instruction_set() {
    if grep -q "avx512" /proc/cpuinfo; then
        echo "v4"  # 支持 AVX-512
    elif grep -q "avx2" /proc/cpuinfo; then
        echo "v3"  # 支持 AVX2
    elif grep -q "avx" /proc/cpuinfo; then
        echo "v2"  # 支持 AVX
    else
        echo "v1"  # 不支持 AVX
    fi
}

# 自动匹配系统架构并下载适配的二进制程序
function install_tuic_binary() {
    if [[ "$(uname -m)" == "x86_64" ]]; then
        ARCH="amd64"
        VERSION=$(detect_instruction_set)
        BINARY_URL="https://github.com/Joseph-ink/tuic-one-key/raw/main/1.0.0/release/${ARCH}/${VERSION}/tuic"
    else
        ARCH="aarch64"
        BINARY_URL="https://github.com/Joseph-ink/tuic-one-key/raw/main/1.0.0/release/${ARCH}/tuic"
    fi

    print_info "检测到架构: $ARCH, 下载版本: $VERSION"
    print_info "正在下载二进制文件: $BINARY_URL"
    curl -Lo "$BINARY_FILE" "$BINARY_URL"
    chmod +x "$BINARY_FILE"

    if [[ ! -f "$BINARY_FILE" ]]; then
        print_error "二进制文件下载失败！"
        exit 1
    fi
    print_success "二进制文件已成功安装到 $BINARY_FILE"
}

# 配置文件生成
function configure_tuic() {
    print_info "生成配置文件..."

    read -p "请输入UUID（回车随机生成UUID）：" UUID
    UUID=${UUID:-$(uuidgen)}

    read -p "请输入密码（回车随机生成12位密码）：" PASSWORD
    PASSWORD=${PASSWORD:-$(openssl rand -base64 12)}

    read -p "请输入端口（回车默认443端口）：" PORT
    PORT=${PORT:-"443"}

    print_info "请选择证书配置方式："
    print_info "1. 自动适配v2ray-agent证书路径（/etc/v2ray-agent/tls/目录）"
    print_info "2. 自定义证书路径"
    print_info "3. 使用默认配置路径（$DEFAULT_CERT 和 $DEFAULT_KEY）"
    read -p "请输入选择（默认3）：" CERT_CHOICE
    CERT_CHOICE=${CERT_CHOICE:-3}

    case $CERT_CHOICE in
        1)
            CERT=$(ls /etc/v2ray-agent/tls/*.crt 2>/dev/null | head -n 1)
            KEY=$(ls /etc/v2ray-agent/tls/*.key 2>/dev/null | head -n 1)
            if [[ -z "$CERT" || -z "$KEY" ]]; then
                print_error "未找到符合条件的证书或私钥文件，请确认路径正确。"
                exit 1
            fi
            ;;
        2)
            read -p "请输入证书路径：" CERT
            read -p "请输入私钥路径：" KEY
            ;;
        *)
            CERT="$DEFAULT_CERT"
            KEY="$DEFAULT_KEY"
            ;;
    esac

    # 添加 zero_rtt_handshake 选项
    read -p "是否开启 zero_rtt_handshake（默认为 false）? (y/n): " ZRTH_CHOICE
    if [[ "$ZRTH_CHOICE" == "y" ]]; then
        ZRTH="true"
    else
        ZRTH="false"
    fi

    cat <<EOF > "$CONFIG_FILE"
{
    "server": "[::]:$PORT",
    "users": {
        "$UUID": "$PASSWORD"
    },
    "certificate": "$CERT",
    "private_key": "$KEY",
    "congestion_control": "bbr",
    "alpn": ["h3"],
    "udp_relay_ipv6": true,
    "zero_rtt_handshake": $ZRTH,
    "dual_stack": true,
    "auth_timeout": "3s",
    "task_negotiation_timeout": "3s",
    "max_idle_time": "10s",
    "max_external_packet_size": 1500,
    "send_window": 16777216,
    "receive_window": 8388608,
    "gc_interval": "3s",
    "gc_lifetime": "15s",
    "log_level": "warn"
}
EOF

    print_success "配置文件已生成: $CONFIG_FILE"
}

# 配置服务文件
function setup_service() {
    print_info "配置服务文件..."
    cat <<EOF > "$SERVICE_FILE"
[Unit]
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=$INSTALL_DIR
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=$BINARY_FILE -c $CONFIG_FILE
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

    print_success "服务文件已配置: $SERVICE_FILE"
    systemctl daemon-reload
    systemctl enable tuic
    print_success "服务文件已启用。"
}

# 启动服务
function start_service() {
    print_info "启动 TUIC 服务..."
    systemctl start tuic
    print_success "服务已启动。您可以通过以下命令查看日志："
    print_info "journalctl -u tuic"
}

# 完全卸载旧版本（保留证书文件）
function uninstall_tuic() {
    print_warning "正在停止服务并卸载旧版本..."
    systemctl stop tuic || true
    systemctl disable tuic || true
    rm -f "$SERVICE_FILE"
    rm -rf "$INSTALL_DIR"
    print_success "旧版本已卸载。"
}

# 主流程
print_info "=== TUIC 安装脚本 ==="
install_dependencies
echo -e "${BLUE}1. 卸载旧版本${NC}"
echo -e "${BLUE}2. 重新安装${NC}"
read -p "请选择操作（默认2）：" ACTION
ACTION=${ACTION:-2}

case $ACTION in
    1)
        uninstall_tuic
        ;;
    2)
        uninstall_tuic
        install_tuic_binary
        configure_tuic
        setup_service
        start_service
        ;;
    *)
        print_error "无效选择，退出。"
        exit 1
        ;;
esac