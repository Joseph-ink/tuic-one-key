## [TUIC](https://github.com/EAimTY/tuic) 一键安装脚本

需要自备证书


### 0.8.5 稳定版
```
wget -N --no-check-certificate "https://raw.githubusercontent.com/Joseph-ink/tuic-one-key/main/0.8.5/install_tuic.sh" && chmod +x install_tuic.sh && ./install_tuic.sh
```

### 1.0.0 测试版
```
wget -N --no-check-certificate "https://raw.githubusercontent.com/Joseph-ink/tuic-one-key/main/1.0.0/install_tuic.sh" && chmod +x install_tuic.sh && ./install_tuic.sh
```


| 项目 | |
| :--- | :--- |
| 程序 | **/etc/tuic/tuic** |
| 配置 | **/etc/tuic/config_server.json** |


## Shadowrocket 配置示例

<details><summary>点击查看</summary><br>

| 选项 | 值 |
| :--- | :--- |
| 类型 | TUIC |
| 地址 | VPS的IP |
| 端口 | 16386 |
| 密码 | chika |
| 模式 | bbr |
| 允许不安全 | 不选 |
| UDP转发 | 选上 |
| SNI | 证书中包含的域名 |
| ALPN | h3 |

</details>
