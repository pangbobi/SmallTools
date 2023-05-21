# Linux系统功能管理


## 安装Python
1. 安装最新版本的Python

    ```shell
    source <(curl -sL https://raw.githubusercontent.com/pangbobi/SmallTools/dev/System/installPython.sh) --latest
    ```

    

2. 安装给定版本的Python，例如：3.8.2版本

    ```shell
    source <(curl -sL https://raw.githubusercontent.com/pangbobi/SmallTools/dev/System/installPython.sh) -v 3.8.2
    ```

## 开启系统防火墙并开机自启

1. 已默认开放SSH端口

    ```shell
    source <(curl -sL https://raw.githubusercontent.com/pangbobi/SmallTools/dev/System/manageFirewall.sh)
    ```

    
