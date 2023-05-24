## [TUIC](https://github.com/EAimTY/tuic) 一键安装脚本

需要自备证书


```
wget -N --no-check-certificate "https://raw.githubusercontent.com/Joseph-ink/tuic-install/main/install_tuic.sh" && chmod +x install_tuic.sh && ./install_tuic.sh
```



| 项目 | |
| :--- | :--- |
| 程序 | **/root/tuic/tuic** |
| 配置 | **/root/tuic/tuic_config.json** |
| 检查 | `/root/tuic/tuic -c tuic_config.json` |
| 查看日志 | `journalctl -u tuic --output cat -e` |
| 实时日志 | `journalctl -u tuic --output cat -f` |


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
