#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

checkOS_URL="https://raw.githubusercontent.com/pangbobi/SmallTools/dev/System/checkOS.sh"

# 初始化防火墙管理工具
Init_Firewall(){
    # 获取并记录SSH端口
    sshPort=$(cat /etc/ssh/sshd_config | grep 'Port '|awk '{print $2}')
    FPM=$(cat $DIR_BASE/config.json |jq -r '.firewall.FPM')
    if [ "$FPM" == "null" ];then
        cat $DIR_BASE/config.json |jq -r '.sshPort'="$sshPort" |sponge $DIR_BASE/config.json
        # 默认开启防火墙
        if [ "${PM}" = "apt-get" ]; then
            apt-get install -y ufw
            if [ -f "/usr/sbin/ufw" ];then
                ufw allow $sshPort
                ufw 80
                ufw 443
                echo y|ufw enable
                ufw default deny
                ufw reload
                ufw status
                FPM="ufw"
            fi
        else
            if [ -f "/etc/init.d/iptables" ];then
                iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport $sshPort -j ACCEPT
                iptables -I INPUT -p udp -m state --state NEW -m udp --dport $sshPort -j ACCEPT
                iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
                iptables -I INPUT -p udp -m state --state NEW -m udp --dport 80 -j ACCEPT
                iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
                iptables -I INPUT -p udp -m state --state NEW -m udp --dport 443 -j ACCEPT
                iptables -A INPUT -p icmp --icmp-type any -j ACCEPT
                iptables -A INPUT -s localhost -d localhost -j ACCEPT
                iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
                iptables -P INPUT DROP
                service iptables save
                sed -i "s#IPTABLES_MODULES=\"\"#IPTABLES_MODULES=\"ip_conntrack_netbios_ns ip_conntrack_ftp ip_nat_ftp\"#" /etc/sysconfig/iptables-config
                iptables_status=$(service iptables status | grep 'not running')
                if [ "${iptables_status}" == '' ];then
                    service iptables restart
                fi
                iptables -L
                FPM="iptables"
            else
                AliyunCheck=$(cat /etc/redhat-release|grep "Aliyun Linux")
                [ "${AliyunCheck}" ] && return
                yum install firewalld -y
                [ "${Centos8Check}" ] && yum reinstall python3-six -y
                systemctl enable firewalld
                systemctl start firewalld
                firewall-cmd --set-default-zone=public > /dev/null 2>&1
                firewall-cmd --permanent --zone=public --add-port=$sshPort/tcp > /dev/null 2>&1
                firewall-cmd --permanent --zone=public --add-port=$sshPort/udp > /dev/null 2>&1
                firewall-cmd --permanent --zone=public --add-port=80/tcp > /dev/null 2>&1
                firewall-cmd --permanent --zone=public --add-port=80/udp > /dev/null 2>&1
                firewall-cmd --permanent --zone=public --add-port=443/tcp > /dev/null 2>&1
                firewall-cmd --permanent --zone=public --add-port=443/udp > /dev/null 2>&1
                firewall-cmd --reload
                firewall-cmd --zone=public --list-ports
                FPM="firewall-cmd"
            fi
        fi
        # 记录并返回防火墙管理工具
        cat $DIR_BASE/config.json |jq -r '.firewall.FPM'='"'$FPM'"' |sponge $DIR_BASE/config.json
    fi
    echo $FPM
}

# 安装依赖
source <(curl -sL $checkOS_URL)

# 防火墙初始化
Init_Firewall
