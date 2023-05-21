#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

checkOS_URL="https://raw.githubusercontent.com/pangbobi/SmallTools/dev/System/checkOS.sh"

# 安装依赖
source <(curl -sL $checkOS_URL)

#######获取参数#########
description=$(Input_Avaliable_Content "请输入对服务的描述")
serviceName=$(Input_Avaliable_Content "请输入用来记录进程ID的文件名")
execStart=$(Input_Avaliable_Content "请输入服务的启动命令")

# 将参数写入文件
cat > /usr/lib/systemd/system/${serviceName}.service <<-EOF
[Unit]
Description=$description
After=network.target

[Service]
Type=simple
PIDFile=/var/run/$serviceName.pid
User=root
ExecStart=$execStart
ExecStop=/bin/kill -s QUIT \$MAINPID
ExecReload=/bin/kill -s HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

# 系统重载服务配置
systemctl daemon-reload
# 开启开机自启
systemctl enable ${serviceName}.service
# 启动服务
systemctl start ${serviceName}.service
# 查看服务状态
service_status=$(systemctl status ${serviceName}.service |grep running)

if [ "${service_status}" ];then
    Green_Info "服务已正常启动！"
else
    Red_Error "服务启动失败！"
fi
systemctl status ${serviceName}.service
