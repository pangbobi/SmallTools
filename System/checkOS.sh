#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

# 脚本存储路径
DIR_BASE="/root"

#颜色信息
Green_Info(){
	echo -e "\033[32m\033[01m$1\033[0m\033[37m\033[01m$2\033[0m"
}
Red_Info(){
	echo -e "\033[31m\033[01m$1\033[0m"
}
White_Info(){
	echo -e "\033[37m\033[01m$1\033[0m"
}
Yellow_Info(){
	echo -e "\033[33m\033[01m$1\033[0m"
}

# 能用性检查
Avaliable_Check(){
    # 用户权限限制
    if [ "$(whoami)" != "root" ];then
        Red_Info "请使用root权限执行此脚本！"
        exit 1;
    fi
    # 系统位数限制
    is64bit=$(getconf LONG_BIT)
    if [ "${is64bit}" != '64' ];then
        Red_Info "抱歉, 当脚本不支持32位系统!";
    fi
    # 系统版本限制
    Centos6Check=$(cat /etc/redhat-release | grep ' 6.' | grep -iE 'centos|Red Hat')
    if [ "${Centos6Check}" ];then
        Red_Info "Centos6不支持此脚本，请更换Centos7/8使用此脚本！"
        exit 1
    fi
    UbuntuCheck=$(cat /etc/issue|grep Ubuntu|awk '{print $2}'|cut -f 1 -d '.')
    if [ "${UbuntuCheck}" ] && [ "${UbuntuCheck}" -lt "16" ];then
        Red_Info "Ubuntu ${UbuntuCheck}不支持此脚本，建议更换Ubuntu18/20使用此脚本！"
        exit 1
    fi
}

# 获取系统安装工具
Get_Pack_Manager(){
	if [ "$(command -v apt-get)" ];then
        PM='apt-get'
    elif [ "$(command -v dnf)" ];then
        PM='dnf'
    elif [ "$(command -v yum)" ];then
        PM='yum'
    else
        Red_Info "不支持的系统！"
        exit 1
    fi
    echo $PM
}

# 安装系统软件
Install_Package(){
    $PM install "$1" -y
    $PM update -y
}

# 卸载系统软件
Remove_Package(){
	local PackageNmae=$1
	if [ "${PM}" == "apt-get" ];then
		isPackage=$(dpkg -l|grep ${PackageNmae})
	else
        isPackage=$(rpm -q ${PackageNmae}|grep "not installed")
	fi
    # 已安装则执行卸载
    if [ -z "${isPackage}" ];then
        $PM remove ${PackageNmae} -y
    fi
}

# 安装基础网络访问工具
Install_Curl_Wget(){
    if [ ! $(which curl) ];then
        Install_Package curl
    fi
    if [ ! $(which wget) ];then
        Install_Package wget
    fi
    if [ ! -f "$DIR_BASE/config.json" ];then
        Install_Package "jq moreutils"
        echo '{"jq-moreutils": "yes"}' > $DIR_BASE/config.json
    fi
}

# 初始化防火墙管理工具
Init_Firewall(){
    # 获取并记录SSH端口
    sshPort=$(cat /etc/ssh/sshd_config | grep 'Port '|awk '{print $2}')
    FPM=$(cat $DIR_BASE/config.json |jq -r '.firewall.FPM')
    if [ ! $FPM ];then
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

# 主函数
main(){
    Avaliable_Check
    Get_Pack_Manager
    Install_Curl_Wget
    Init_Firewall
}
# 执行主函数
main
