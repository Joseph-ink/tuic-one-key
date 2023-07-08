## [TUIC](https://github.com/EAimTY/tuic) 一键安装脚本

需要自备证书


### 0.8.5 稳定版
```
wget -N --no-check-certificate "https://raw.githubusercontent.com/Joseph-ink/tuic-one-key/main/0.8.5/install_tuic.sh" && chmod +x install_tuic.sh && ./install_tuic.sh
```

### 1.0.0 正式版
```
wget -N --no-check-certificate "https://raw.githubusercontent.com/Joseph-ink/tuic-one-key/main/1.0.0/install_tuic.sh" && chmod +x install_tuic.sh && ./install_tuic.sh
```


| 项目 | |
| :--- | :--- |
| 程序 | **/etc/tuic/tuic** |
| 配置 | **/etc/tuic/config_server.json** |


## 编译优化

<details><summary>点击查看</summary><br>
/realm/realm_core/src/udp/mod.rs
#UDP buffer size 4096

/realm/realm_io/Cargo.toml
/realm/realm_core/Cargo.toml
#tokio 1
</details>
