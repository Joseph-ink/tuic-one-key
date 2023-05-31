#!/bin/bash

# 移除之前的安装
systemctl stop tuic
rm /etc/systemd/system/tuic.service
rm -rf /etc/tuic

# 创建目录
mkdir -p /etc/tuic

# 自动匹配系统架构并下载二进制程序
if [[ "$(uname -m)" == "x86_64" ]]; then
  ARCH="x86_64-unknown"
else
  ARCH="aarch64-unknown"
fi
curl -Lo /etc/tuic/tuic https://github.com/EAimTY/tuic/releases/download/tuic-server-1.0.0-beta0/tuic-server-1.0.0-beta0-${ARCH}-linux-gnu
chmod +x /etc/tuic/tuic


# 下载配置文件
curl -Lo /etc/tuic/tuic_config.json https://raw.githubusercontent.com/Joseph-ink/tuic-one-key/main/1.0.0/config_server.json

# 提示用户输入配置参数
read -p "是否自定义UUID（否则自动生成）? (y/n)：" UUID_CHOICE
if [[ "$UUID_CHOICE" == "y" ]]; then
  read -p "请输入UUID：" UUID
else
  UUID=$(uuidgen)
fi

read -p "是否自定义密码（否则随机生成8位密码）? (y/n)：" PASS_CHOICE
if [[ "$PASS_CHOICE" == "y" ]]; then
  read -p "请输入密码：" PASSWORD
else
  PASSWORD=$(openssl rand -base64 6)
fi

read -p "是否自定义端口（否则默认443端口）? (y/n)：" PORT_CHOICE
if [[ "$PORT_CHOICE" == "y" ]]; then
  read -p "请输入端口：" PORT
else
  PORT="443"
fi

# 选择证书配置方式
echo "请选择证书配置方式："
echo "1. 自动适配v2ray-agent证书路径（位于/etc/v2ray-agent/tls/目录下）"
echo "2. 自定义证书路径"
echo "3. 使用默认配置路径（位于/root/cert/目录下）"
read -p "请输入选择（默认3）：" CERT_CHOICE
CERT_CHOICE=${CERT_CHOICE:-3}

case $CERT_CHOICE in
  1)
    # 自动适配V2ray-agent证书路径
    CERT=$(ls /etc/v2ray-agent/tls/*.crt)
    PRIV_KEY=$(ls /etc/v2ray-agent/tls/*.key)
    ;;
  2)
    # 自定义证书路径
    read -p "请输入fullchain证书路径：" CERT
    read -p "请输入私钥证书路径：" PRIV_KEY
    ;;
  3)
    # 使用默认配置路径
    CERT="/root/cert/cert.crt"
    PRIV_KEY="/root/cert/private.key"
    echo "请确保证书已上传至默认路径"
    ;;
  *)
    # 输入无效，使用默认配置路径
    echo "输入无效，使用默认配置路径"
    CERT="/root/cert/cert.crt"
    PRIV_KEY="/root/cert/private.key"
    echo "请确保证书已上传至默认路径"
    ;;
esac

read -p "是否开启zero_rtt_handshake（默认为false）? (y/n)：" ZRTH_CHOICE
if [[ "$ZRTH_CHOICE" == "y" ]]; then
  ZRTH="true"
else
  ZRTH="false"
fi

# 替换配置文件中的参数
sed -i "s|\"server\": \"[::]:443\"|\"server\": \"[::]:${PORT}\"|g" /etc/tuic/tuic_config.json
sed -i "s|\"00000000-0000-0000-0000-000000000000\": \"PASSWORD\"|\"${UUID}\": \"${PASSWORD}\"|g" /etc/tuic/tuic_config.json
sed -i "s|\"certificate\": \"/root/cert/cert.crt\"|\"certificate\": \"${CERT}\"|g" /etc/tuic/tuic_config.json
sed -i "s|\"private_key\": \"/root/cert/private.key\"|\"private_key\": \"${PRIV_KEY}\"|g" /etc/tuic/tuic_config.json
sed -i "s|\"zero_rtt_handshake\": false|\"zero_rtt_handshake\": ${ZRTH}|g" /etc/tuic/tuic_config.json

# 下载systemctl配置
curl -Lo /etc/systemd/system/tuic.service https://raw.githubusercontent.com/Joseph-ink/tuic-one-key/main/1.0.0/tuic.service
systemctl daemon-reload

# 启动程序
systemctl enable --now tuic && sleep 0.2 && systemctl status tuic
