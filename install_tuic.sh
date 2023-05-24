#!/bin/bash

# 创建目录
mkdir -p /root/tuic

# 自动匹配系统架构并下载二进制程序
if [[ "$(uname -m)" == "x86_64" ]]; then
  ARCH="x86_64"
else
  ARCH="aarch64"
fi
curl -Lo /root/tuic/tuic https://github.com/EAimTY/tuic/releases/download/0.8.5/tuic-server-0.8.5-${ARCH}-linux-gnu
chmod +x /root/tuic/tuic

# 下载配置文件
curl -Lo /root/tuic/tuic_config.json https://raw.githubusercontent.com/Joseph-ink/tuic-install/main/config_server.json

# 提示用户输入配置参数
read -p "请输入tuic端口号（默认16386）：" PORT
PORT=${PORT:-16386}
read -p "请输入tuic密码（默认chika）：" TOKEN
TOKEN=${TOKEN:-chika}
read -p "请输入fullchain证书地址（默认 /root/cert/cert.crt）：" CERT
CERT=${CERT:-/root/cert/cert.crt}
read -p "请输入证书私钥地址（默认 /root/cert/private.key）：" PRIV_KEY
PRIV_KEY=${PRIV_KEY:-/root/cert/private.key}

# 替换配置文件中的参数
sed -i "s/\"port\": 16386/\"port\": ${PORT}/g" /root/tuic/tuic_config.json
sed -i "s/\"token\": \[\"chika\"\]/\"token\": [\"${TOKEN}\"]/g" /root/tuic/tuic_config.json
sed -i "s|\"certificate\": \"/root/cert/cert.crt\"|\"certificate\": \"${CERT}\"|g" /root/tuic/tuic_config.json
sed -i "s|\"private_key\": \"/root/cert/private.key\"|\"private_key\": \"${PRIV_KEY}\"|g" /root/tuic/tuic_config.json

# 下载systemctl配置
curl -Lo /etc/systemd/system/tuic.service https://raw.githubusercontent.com/Joseph-ink/tuic-install/main/tuic.service
systemctl daemon-reload

# 启动程序
systemctl enable --now tuic && sleep 0.2 && systemctl status tuic
