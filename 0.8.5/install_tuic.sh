#!/bin/bash

# 移除之前的安装
systemctl stop tuic
rm /etc/systemd/system/tuic.service
rm -rf /etc/tuic

# 创建目录
mkdir -p /etc/tuic

# 自动匹配系统架构并下载二进制程序
if [[ "$(uname -m)" == "x86_64" ]]; then
  ARCH="x86_64"
else
  ARCH="aarch64"
fi
curl -Lo /etc/tuic/tuic https://github.com/EAimTY/tuic/releases/download/0.8.5/tuic-server-0.8.5-${ARCH}-linux-gnu
chmod +x /etc/tuic/tuic


# 下载配置文件
curl -Lo /etc/tuic/config_server.json https://raw.githubusercontent.com/Joseph-ink/tuic-one-key/main/0.8.5/config_server.json

# 提示用户输入配置参数
read -p "请输入tuic端口号（默认16386）：" PORT
PORT=${PORT:-16386}
read -p "请输入tuic密码（默认chika）：" TOKEN
TOKEN=${TOKEN:-chika}

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

# 替换配置文件中的参数
sed -i "s/\"port\": 16386/\"port\": ${PORT}/g" /etc/tuic/config_server.json
sed -i "s/\"token\": \[\"chika\"\]/\"token\": [\"${TOKEN}\"]/g" /etc/tuic/config_server.json
sed -i "s|\"certificate\": \"/root/cert/cert.crt\"|\"certificate\": \"${CERT}\"|g" /etc/tuic/config_server.json
sed -i "s|\"private_key\": \"/root/cert/private.key\"|\"private_key\": \"${PRIV_KEY}\"|g" /etc/tuic/config_server.json

# 下载systemctl配置
curl -Lo /etc/systemd/system/tuic.service https://raw.githubusercontent.com/Joseph-ink/tuic-one-key/main/0.8.5/tuic.service
systemctl daemon-reload

# 启动程序
systemctl enable --now tuic && sleep 0.2 && systemctl status tuic
