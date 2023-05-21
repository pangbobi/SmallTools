# 自定义跟随系统自启的服务功能模块

## [Linux中systemctl命令理解以及.service文件参数解析](https://blog.csdn.net/weixin_45606237/article/details/124727920)

## 模板文件

1. template.service主要参数说明：

    | 参数名      | 备注                         | 默认值                                   | 替换输入                                               |
    | ----------- | ---------------------------- | ---------------------------------------- | ------------------------------------------------------ |
    | Description | 对服务的说明                 | <Functional_Description_of_This_Service> | 用自己对该进程的描述替换掉包括尖括号在内的左侧默认值   |
    | PIDFile     | 存储服务进程的文件           | <Service_Name>                           | 用自己对该服务的命名替换掉包括尖括号在内的左侧默认值   |
    | ExecStart   | 服务启动命令，应使用绝对路径 | <The_Start_Command_for_This_Service>     | 用自定义服务的启动命令替换掉包括尖括号在内的左侧默认值 |


## 如何使用

1. 执行如下Shell脚本在命令行输入参数，自动部署

    ```shell
    source <(curl -sL https://raw.githubusercontent.com/pangbobi/SmallTools/dev/System/autoStart/customizeService.sh)
    ```

2. 核心操作

    | 功能         | systemd命令                    | Init系统命令                 |
    | ------------ | ------------------------------ | ---------------------------- |
    | 启动服务     | systemctl start Service_Name   | service Service_Name start   |
    | 停止服务     | systemctl stop Service_Name    | service Service_Name stop    |
    | 重启服务     | systemctl restart Service_Name | service Service_Name restart |
    | 查看服务状态 | systemctl status Service_Name  | service Service_Name status  |

    