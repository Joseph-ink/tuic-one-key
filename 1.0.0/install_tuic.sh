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
curl -Lo /etc/tuic/tuic https://github.com/Joseph-ink/tuic-one-key/raw/main/1.0.0/release/amd64/v3/tuic
chmod +x /etc/tuic/tuic

# 下载配置文件
curl -Lo /etc/tuic/config_server.json https://raw.githubusercontent.com/Joseph-ink/tuic-one-key/main/1.0.0/config_server.json

# 提示用户输入配置参数
read -p "请输入UUID（回车随机生成UUID）：" UUID
UUID=${UUID:-$(uuidgen)}

read -p "请输入密码（回车随机生成8位密码）：" PASSWORD
PASSWORD=${PASSWORD:-$(openssl rand -base64 6)}

read -p "请输入端口（回车默认443端口）：" PORT
PORT=${PORT:-"443"}


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
sed -i "s|\"server\": \"\[\:\:\]:443\"|\"server\": \"\[\:\:\]:${PORT}\"|g" /etc/tuic/config_server.json
sed -i "s|\"00000000-0000-0000-0000-000000000000\": \"PASSWORD\"|\"${UUID}\": \"${PASSWORD}\"|g" /etc/tuic/config_server.json
sed -i "s|\"certificate\": \"/root/cert/cert.crt\"|\"certificate\": \"${CERT}\"|g" /etc/tuic/config_server.json
sed -i "s|\"private_key\": \"/root/cert/private.key\"|\"private_key\": \"${PRIV_KEY}\"|g" /etc/tuic/config_server.json
sed -i "s|\"zero_rtt_handshake\": false|\"zero_rtt_handshake\": ${ZRTH}|g" /etc/tuic/config_server.json

# 下载systemctl配置
curl -Lo /etc/systemd/system/tuic.service https://raw.githubusercontent.com/Joseph-ink/tuic-one-key/main/1.0.0/tuic.service
systemctl daemon-reload

# 启动程序
systemctl enable --now tuic && sleep 0.2 && systemctl status tuic

# 检查程序运行并输出重要配置信息
if [[ $(systemctl is-active tuic) == "active" ]]
then
    echo "--------------------------------------------"
    echo "安装成功!"
    echo "--------------------------------------------"
    echo "UUID: $UUID"
    echo "密码: $PASSWORD"
    echo "端口: $PORT"
    echo "--------------------------------------------"
else
    echo "程序启动失败，请检查安装过程或查看相关日志"
fi
